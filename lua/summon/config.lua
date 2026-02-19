local M = {}

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

local function validate(cfg)
    if cfg.highlights then
        for group, attrs in pairs(cfg.highlights) do
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

    for cmd_name, cmd_cfg in pairs(cfg.commands) do
        if cmd_cfg.border_color and type(cmd_cfg.border_color) ~= "string" and type(cmd_cfg.border_color) ~= "number" then
            vim.notify(
                string.format(
                    'summon.nvim: commands.%s.border_color should be a hex string (e.g. "#e78a4e") or number, got %s',
                    cmd_name,
                    type(cmd_cfg.border_color)
                ),
                vim.log.levels.WARN
            )
        end
    end
end

function M.merge(opts)
    opts = opts or {}

    config = vim.tbl_deep_extend("force", default_globals, opts)

    if opts.commands then
        config.commands = opts.commands
    else
        config.commands = default_commands
    end

    validate(config)
end

function M.get()
    return config
end

return M
