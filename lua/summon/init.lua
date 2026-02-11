local M = {}

local bufs = {}

local default_globals = {
    width = 0.85,
    height = 0.85,
    border = "rounded",
    close_keymap = "<Esc><Esc>",
    highlights = {
        float = { bg = "#282828" },
        border = { fg = "#d79921", bg = "#282828" },
        title = { fg = "#282828", bg = "#d79921", bold = true },
    },
}

local default_commands = {
    claude = {
        command = "claude",
        title = " Claude ",
        keymap = "<leader>c",
    },
}

local config = {}

local function set_highlights()
    vim.api.nvim_set_hl(0, "SummonFloat", config.highlights.float)
    vim.api.nvim_set_hl(0, "SummonBorder", config.highlights.border)
    vim.api.nvim_set_hl(0, "SummonTitle", config.highlights.title)
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

    -- Reuse existing terminal buffer if still valid
    if bufs[name] and vim.api.nvim_buf_is_valid(bufs[name]) then
        -- buffer exists, reuse it
    else
        bufs[name] = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_call(bufs[name], function()
            vim.fn.termopen(cmd_config.command, {
                on_exit = function()
                    bufs[name] = nil
                end,
            })
        end)
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

    vim.cmd("startinsert")

    vim.keymap.set("t", close_keymap, function()
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, false)
        end
    end, { buffer = bufs[name] })
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

    vim.g.terminal_color_0 = config.highlights.float.bg or "#282828"

    set_highlights()

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
