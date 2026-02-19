local config = require("summon.config")
local highlights = require("summon.highlights")

local M = {}

local bufs = {}

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

    if bufs[name] and vim.api.nvim_buf_is_valid(bufs[name]) then
        -- buffer exists, reuse it
    else
        if buffer_type == "terminal" then
            bufs[name] = vim.api.nvim_create_buf(false, true)

            -- Set buffer-local terminal foreground colors so ANSI text has
            -- proper contrast against the float background
            local hl = cfg.highlights or highlights.detect()
            if hl.float.fg then
                local fg_hex = highlights.color_to_hex(hl.float.fg)
                vim.b[bufs[name]].terminal_color_7 = fg_hex
                vim.b[bufs[name]].terminal_color_15 = fg_hex
            end

            vim.api.nvim_buf_call(bufs[name], function()
                vim.fn.termopen(cmd_config.command, {
                    on_exit = function()
                        bufs[name] = nil
                    end,
                })
            end)
        elseif buffer_type == "file" then
            local file_path = vim.fn.expand(cmd_config.command)

            if vim.fn.filereadable(file_path) == 0 then
                vim.fn.writefile({}, file_path)
            end

            bufs[name] = vim.fn.bufadd(file_path)
            vim.bo[bufs[name]].swapfile = false
            vim.fn.bufload(bufs[name])
            vim.bo[bufs[name]].bufhidden = "wipe"

            if cmd_config.filetype then
                vim.bo[bufs[name]].filetype = cmd_config.filetype
            end
        else
            vim.notify("Summon: unknown buffer type '" .. buffer_type .. "'", vim.log.levels.ERROR)
            return
        end
    end

    local w = math.floor(vim.o.columns * width)
    local h = math.floor(vim.o.lines * height)
    local row = math.floor((vim.o.lines - h) / 2)
    local col = math.floor((vim.o.columns - w) / 2)

    local win = vim.api.nvim_open_win(bufs[name], true, {
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
        end, { buffer = bufs[name], nowait = true })

        local passthrough_keys = cmd_config.terminal_passthrough_keys or cfg.terminal_passthrough_keys
        if passthrough_keys and #passthrough_keys > 0 then
            for _, key in ipairs(passthrough_keys) do
                pcall(vim.keymap.set, "t", key, key, {
                    buffer = bufs[name],
                    nowait = true,
                    desc = "Pass " .. key .. " to terminal"
                })
            end
        end
    elseif buffer_type == "file" then
        vim.keymap.set("n", close_keymap, function()
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, false)
            end
        end, { buffer = bufs[name], nowait = true })

        vim.keymap.set("n", "q", function()
            if vim.api.nvim_win_is_valid(win) then
                vim.cmd("silent! noautocmd write")
                vim.api.nvim_win_close(win, false)
            end
        end, { buffer = bufs[name], nowait = true })
    end
end

return M
