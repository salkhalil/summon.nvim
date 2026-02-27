local config = require("summon.config")
local highlights = require("summon.highlights")

local M = {}

local bufs = {}

local function join_path(...)
    return vim.fs.joinpath(...)
end

local function get_buffer_key(buffer_type, name, file_path)
    if buffer_type == "terminal" then
        return "terminal:" .. name
    end

    return "file:" .. file_path
end

local function get_start_dir()
    local bufnr = vim.api.nvim_get_current_buf()
    local bufname = vim.api.nvim_buf_get_name(bufnr)

    if vim.bo[bufnr].buftype == "" and bufname ~= "" then
        return vim.fs.dirname(vim.fn.fnamemodify(bufname, ":p"))
    end

    return vim.fn.getcwd()
end

local function marker_exists(path)
    return vim.fn.isdirectory(path) == 1 or vim.fn.filereadable(path) == 1
end

local function find_project_root(start_dir, marker)
    local dir = vim.fn.fnamemodify(start_dir, ":p")

    while dir and dir ~= "" do
        if marker_exists(join_path(dir, marker)) then
            return dir
        end

        local parent = vim.fs.dirname(dir)
        if not parent or parent == dir then
            break
        end

        dir = parent
    end

    return nil
end

local function resolve_project_file_path(cmd_config)
    local root_pattern = cmd_config.root_pattern or ".git"
    local start_dir = get_start_dir()
    local project_root = find_project_root(start_dir, root_pattern) or vim.fn.getcwd()

    return join_path(project_root, cmd_config.command)
end

local function ensure_parent_dir(file_path)
    local parent_dir = vim.fs.dirname(file_path)

    if parent_dir and parent_dir ~= "" and vim.fn.isdirectory(parent_dir) == 0 then
        vim.fn.mkdir(parent_dir, "p")
    end
end

local function open_file_buffer(cache_key, file_path, cmd_config)
    if bufs[cache_key] and vim.api.nvim_buf_is_valid(bufs[cache_key]) then
        return bufs[cache_key]
    end

    ensure_parent_dir(file_path)

    if vim.fn.filereadable(file_path) == 0 then
        vim.fn.writefile({}, file_path)
    end

    bufs[cache_key] = vim.fn.bufadd(file_path)
    vim.bo[bufs[cache_key]].swapfile = false
    vim.fn.bufload(bufs[cache_key])
    vim.bo[bufs[cache_key]].bufhidden = "wipe"

    if cmd_config.filetype then
        vim.bo[bufs[cache_key]].filetype = cmd_config.filetype
    end

    return bufs[cache_key]
end

function M.open(name)
    local cfg = config.get()
    local cmd_config = cfg.commands[name]
    if not cmd_config then
        vim.notify("Summon: unknown command '" .. name .. "'", vim.log.levels.ERROR)
        return
    end

    local width = cmd_config.width or cfg.width
    local height = cmd_config.height or cfg.height
    local border = cmd_config.border or cfg.border
    local close_keymap = cmd_config.close_keymap or cfg.close_keymap
    local title = cmd_config.title or (" " .. name .. " ")

    local buffer_type = cmd_config.type or "terminal"
    local file_path
    if buffer_type == "file" then
        file_path = vim.fn.expand(cmd_config.command)
    elseif buffer_type == "project_file" then
        file_path = resolve_project_file_path(cmd_config)
    end

    local buffer_key = get_buffer_key(buffer_type, name, file_path)

    if bufs[buffer_key] and vim.api.nvim_buf_is_valid(bufs[buffer_key]) then
        -- buffer exists, reuse it
    else
        if buffer_type == "terminal" then
            bufs[buffer_key] = vim.api.nvim_create_buf(false, true)

            -- Set buffer-local terminal foreground colors so ANSI text has
            -- proper contrast against the float background
            local hl = cfg.highlights or highlights.detect()
            if hl.float.fg then
                local fg_hex = highlights.color_to_hex(hl.float.fg)
                vim.b[bufs[buffer_key]].terminal_color_7 = fg_hex
                vim.b[bufs[buffer_key]].terminal_color_15 = fg_hex
            end

            vim.api.nvim_buf_call(bufs[buffer_key], function()
                vim.fn.termopen(cmd_config.command, {
                    on_exit = function()
                        bufs[buffer_key] = nil
                    end,
                })
            end)
        elseif buffer_type == "file" or buffer_type == "project_file" then
            open_file_buffer(buffer_key, file_path, cmd_config)
        else
            vim.notify("Summon: unknown buffer type '" .. buffer_type .. "'", vim.log.levels.ERROR)
            return
        end
    end

    local w = math.floor(vim.o.columns * width)
    local h = math.floor(vim.o.lines * height)
    local row = math.floor((vim.o.lines - h) / 2)
    local col = math.floor((vim.o.columns - w) / 2)

    local win = vim.api.nvim_open_win(bufs[buffer_key], true, {
        relative = "editor",
        width = w,
        height = h,
        row = row,
        col = col,
        border = border,
        title = title,
        title_pos = "center",
        style = "minimal",
    })

    local winhl = "Normal:SummonFloat,FloatBorder:SummonBorder,FloatTitle:SummonTitle"
    if cmd_config.border_color then
        highlights.apply_command(name, cmd_config.border_color, cfg)
        winhl = "Normal:SummonFloat,FloatBorder:SummonBorder_" .. name .. ",FloatTitle:SummonTitle_" .. name
    end

    vim.api.nvim_win_set_option(win, "winhl", winhl)

    if buffer_type == "terminal" then
        vim.cmd("startinsert")

        vim.keymap.set("t", close_keymap, function()
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, false)
            end
        end, { buffer = bufs[buffer_key], nowait = true })

        local passthrough_keys = cmd_config.terminal_passthrough_keys or cfg.terminal_passthrough_keys
        if passthrough_keys and #passthrough_keys > 0 then
            for _, key in ipairs(passthrough_keys) do
                pcall(vim.keymap.set, "t", key, key, {
                    buffer = bufs[buffer_key],
                    nowait = true,
                    desc = "Pass " .. key .. " to terminal"
                })
            end
        end
    elseif buffer_type == "file" or buffer_type == "project_file" then
        vim.keymap.set("n", close_keymap, function()
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, false)
            end
        end, { buffer = bufs[buffer_key], nowait = true })

        vim.keymap.set("n", "q", function()
            if vim.api.nvim_win_is_valid(win) then
                vim.cmd("silent! noautocmd write")
                vim.api.nvim_win_close(win, false)
            end
        end, { buffer = bufs[buffer_key], nowait = true })
    end
end

return M
