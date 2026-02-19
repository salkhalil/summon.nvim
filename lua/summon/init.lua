local M = {}

local bufs = {}

local default_globals = {
    width = 0.85,
    height = 0.85,
    border = "rounded",
    close_keymap = "<Esc><Esc>",
    highlights = nil, -- nil = auto-detect from colorscheme
    terminal_passthrough_keys = { "<C-o>", "<C-i>" },
}

local default_commands = {
    claude = {
        command = "claude",
        title = " Claude ",
        keymap = "<leader>c",
    },
}

local config = {}

local function color_to_hex(val)
    if type(val) == "number" then
        return string.format("#%06x", val)
    end
    return val
end

local function detect_highlights()
    local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
    local normal_float = vim.api.nvim_get_hl(0, { name = "NormalFloat" })
    local border = vim.api.nvim_get_hl(0, { name = "FloatBorder", link = false })
    local title = vim.api.nvim_get_hl(0, { name = "FloatTitle", link = false })
    local title_hl = vim.api.nvim_get_hl(0, { name = "Title", link = false })

    -- Only use NormalFloat bg if the colorscheme explicitly links or defines it,
    -- otherwise many colorschemes leave it at Neovim's default which looks out of place
    local bg = normal.bg
    local fg = normal.fg
    local float_fg = fg
    if normal_float.link then
        local resolved = vim.api.nvim_get_hl(0, { name = normal_float.link, link = false })
        bg = resolved.bg or bg
        float_fg = resolved.fg or float_fg
    elseif normal_float.bg and normal_float.fg then
        -- Both fg and bg set suggests intentional colorscheme definition
        bg = normal_float.bg
        float_fg = normal_float.fg
    end

    -- Prefer the colorscheme's accent color (Title) over plain Normal fg for borders
    local accent = border.fg or title_hl.fg or fg

    return {
        float = { fg = float_fg, bg = bg },
        border = { fg = accent, bg = bg },
        title = { fg = title.fg or bg, bg = title.bg or accent, bold = true },
    }
end

local function set_highlights()
    local hl = config.highlights or detect_highlights()
    vim.api.nvim_set_hl(0, "SummonFloat", hl.float)
    vim.api.nvim_set_hl(0, "SummonBorder", hl.border)
    vim.api.nvim_set_hl(0, "SummonTitle", hl.title)
end

function M.open(name)
    local cmd_config = config.commands[name]
    if not cmd_config then
        vim.notify("Summon: unknown command '" .. name .. "'", vim.log.levels.ERROR)
        return
    end

    -- Resolve per-command overrides with global defaults
    local width = cmd_config.width or config.width
    local height = cmd_config.height or config.height
    local border = cmd_config.border or config.border
    local close_keymap = cmd_config.close_keymap or config.close_keymap
    local title = cmd_config.title or (" " .. name .. " ")

    -- Determine buffer type (default to "terminal" for backward compatibility)
    local buffer_type = cmd_config.type or "terminal"

    -- Reuse existing buffer if still valid
    if bufs[name] and vim.api.nvim_buf_is_valid(bufs[name]) then
        -- buffer exists, reuse it
    else
        if buffer_type == "terminal" then
            -- Create terminal buffer
            bufs[name] = vim.api.nvim_create_buf(false, true)

            -- Set buffer-local terminal foreground colors so ANSI text has
            -- proper contrast against the float background
            local hl = config.highlights or detect_highlights()
            if hl.float.fg then
                local fg_hex = color_to_hex(hl.float.fg)
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
            -- Create file buffer
            local file_path = vim.fn.expand(cmd_config.command)

            -- Always create file if it doesn't exist
            if vim.fn.filereadable(file_path) == 0 then
                vim.fn.writefile({}, file_path)
            end

            bufs[name] = vim.fn.bufadd(file_path)
            vim.bo[bufs[name]].swapfile = false
            vim.fn.bufload(bufs[name])
            vim.bo[bufs[name]].bufhidden = "wipe"

            -- Override filetype if specified
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

    vim.api.nvim_win_set_option(win, "winhl", "Normal:SummonFloat,FloatBorder:SummonBorder,FloatTitle:SummonTitle")

    -- Set up keymaps based on buffer type
    if buffer_type == "terminal" then
        -- Enter insert mode for terminal buffers
        vim.cmd("startinsert")

        -- Close keymap in terminal mode
        vim.keymap.set("t", close_keymap, function()
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, false)
            end
        end, { buffer = bufs[name], nowait = true })

        -- Set up passthrough keymaps for terminal mode
        local passthrough_keys = cmd_config.terminal_passthrough_keys or config.terminal_passthrough_keys
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
        -- Stay in normal mode for file buffers

        -- Close keymap in normal mode
        vim.keymap.set("n", close_keymap, function()
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, false)
            end
        end, { buffer = bufs[name], nowait = true })

        -- Also map 'q' for quick exit
        vim.keymap.set("n", "q", function()
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, false)
            end
        end, { buffer = bufs[name], nowait = true })
    end
end

function M.setup(opts)
    opts = opts or {}

    -- Merge global options
    config = vim.tbl_deep_extend("force", default_globals, opts)

    -- Merge commands: user commands override defaults entirely
    if opts.commands then
        config.commands = opts.commands
    else
        config.commands = default_commands
    end

    -- Validate highlight color fields
    if config.highlights then
        for group, attrs in pairs(config.highlights) do
            for key, val in pairs(attrs) do
                if (key == "fg" or key == "bg") and type(val) ~= "string" and type(val) ~= "number" then
                    vim.notify(
                        string.format("summon.nvim: highlights.%s.%s should be a hex string (e.g. \"#282828\") or number, got %s", group, key, type(val)),
                        vim.log.levels.WARN
                    )
                end
            end
        end
    end

    set_highlights()

    -- Sync terminal ANSI black with float background
    local hl = config.highlights or detect_highlights()
    if hl.float.bg then
        vim.g.terminal_color_0 = color_to_hex(hl.float.bg)
    end

    -- Re-apply highlights when colorscheme changes (only matters for auto-detect)
    if not config.highlights then
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("SummonHighlights", { clear = true }),
            callback = function()
                set_highlights()
                local detected = detect_highlights()
                if detected.float.bg then
                    vim.g.terminal_color_0 = color_to_hex(detected.float.bg)
                end
            end,
        })
    end

    -- Bind keymaps for each command that has one
    for name, cmd_config in pairs(config.commands) do
        if cmd_config.keymap then
            vim.keymap.set("n", cmd_config.keymap, function()
                M.open(name)
            end, { desc = "Summon " .. name })
        end
    end
end

function M._get_commands()
    return config.commands or {}
end

return M
