local M = {}

local default_globals = {
    width = 0.85,
    height = 0.85,
    border = "rounded",
    close_keymap = "<Esc><Esc>",
    highlights = nil, -- nil = auto-detect from colorscheme
    terminal_passthrough_keys = { "<C-o>", "<C-i>" },
    select_keymap = nil,
}

local default_commands = {
    claude = {
        command = "claude",
        title = " Claude ",
        keymap = "<leader>c",
        border_color = "#FFA500"
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

    if cfg.select_keymap ~= nil and type(cfg.select_keymap) ~= "string" then
        vim.notify("summon.nvim: select_keymap should be a string", vim.log.levels.WARN)
    end

    for cmd_name, cmd_cfg in pairs(cfg.commands) do
        local cmd_type = cmd_cfg.type or "terminal"

        if cmd_type ~= "terminal" and cmd_type ~= "file" and cmd_type ~= "project_file" then
            vim.notify(
                string.format(
                    'summon.nvim: commands.%s.type should be "terminal", "file", or "project_file", got %q',
                    cmd_name,
                    tostring(cmd_type)
                ),
                vim.log.levels.WARN
            )
        end

        if type(cmd_cfg.command) ~= "string" then
            vim.notify(
                string.format("summon.nvim: commands.%s.command should be a string", cmd_name),
                vim.log.levels.WARN
            )
        end

        if cmd_type == "project_file" and cmd_cfg.root_pattern ~= nil and type(cmd_cfg.root_pattern) ~= "string" then
            vim.notify(
                string.format("summon.nvim: commands.%s.root_pattern should be a string", cmd_name),
                vim.log.levels.WARN
            )
        end

        if cmd_cfg.reload ~= nil and type(cmd_cfg.reload) ~= "boolean" then
            vim.notify(
                string.format("summon.nvim: commands.%s.reload should be a boolean", cmd_name),
                vim.log.levels.WARN
            )
        end

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
