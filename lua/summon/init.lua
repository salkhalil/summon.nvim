local config = require("summon.config")
local highlights = require("summon.highlights")
local window = require("summon.window")

local M = {}

function M.open(name)
    window.open(name)
end

function M.setup(opts)
    config.merge(opts)

    local cfg = config.get()

    highlights.apply(cfg)

    -- Sync terminal ANSI black with float background
    local hl = cfg.highlights or highlights.detect()
    if hl.float.bg then
        vim.g.terminal_color_0 = highlights.color_to_hex(hl.float.bg)
    end

    -- Re-apply highlights when colorscheme changes (only matters for auto-detect)
    if not cfg.highlights then
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("SummonHighlights", { clear = true }),
            callback = function()
                highlights.apply(cfg)
                local detected = highlights.detect()
                if detected.float.bg then
                    vim.g.terminal_color_0 = highlights.color_to_hex(detected.float.bg)
                end
                for cmd_name, cmd_cfg in pairs(cfg.commands) do
                    if cmd_cfg.border_color then
                        highlights.apply_command(cmd_name, cmd_cfg.border_color, cfg)
                    end
                end
            end,
        })
    end

    -- Bind keymaps for each command that has one
    for name, cmd_config in pairs(cfg.commands) do
        if cmd_config.keymap then
            vim.keymap.set("n", cmd_config.keymap, function()
                M.open(name)
            end, { desc = "Summon " .. name })
        end
    end
end

function M._get_commands()
    return config.get().commands or {}
end

return M
