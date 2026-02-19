local M = {}

function M.color_to_hex(val)
    if type(val) == "number" then
        return string.format("#%06x", val)
    end
    return val
end

function M.detect()
    local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
    local normal_float = vim.api.nvim_get_hl(0, { name = "NormalFloat" })
    local border = vim.api.nvim_get_hl(0, { name = "FloatBorder", link = false })
    local title = vim.api.nvim_get_hl(0, { name = "FloatTitle", link = false })

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
        bg = normal_float.bg
        float_fg = normal_float.fg
    end

    -- Prefer the colorscheme's accent color (Title) over plain Normal fg for borders
    local accent = border.fg or fg

    return {
        float = { fg = float_fg, bg = bg },
        border = { fg = accent, bg = bg },
        title = { fg = title.fg or bg, bg = title.bg or accent, bold = true },
    }
end

function M.apply(cfg)
    local hl = cfg.highlights or M.detect()
    vim.api.nvim_set_hl(0, "SummonFloat", hl.float)
    vim.api.nvim_set_hl(0, "SummonBorder", hl.border)
    vim.api.nvim_set_hl(0, "SummonTitle", hl.title)
end

function M.apply_command(name, border_color, cfg)
    local hl = cfg.highlights or M.detect()
    local float_bg = hl.float.bg
    vim.api.nvim_set_hl(0, "SummonBorder_" .. name, { fg = border_color, bg = float_bg })
    vim.api.nvim_set_hl(0, "SummonTitle_" .. name, { fg = float_bg, bg = border_color, bold = true })
end

return M
