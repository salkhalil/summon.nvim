local M = {}

local buf = nil
local default_config = {
    command = "claude",
    title = " Claude ",
    width = 0.85,
    height = 0.85,
    border = "rounded",
    keymap = "<leader>c",
    close_keymap = "<Esc><Esc>",
    highlights = {
        float = { bg = "#282828" },
        border = { fg = "#d79921", bg = "#282828" },
        title = { fg = "#282828", bg = "#d79921", bold = true },
    },
}

local config = {}

local function set_highlights()
    vim.api.nvim_set_hl(0, "SummonFloat", config.highlights.float)
    vim.api.nvim_set_hl(0, "SummonBorder", config.highlights.border)
    vim.api.nvim_set_hl(0, "SummonTitle", config.highlights.title)
end

function M.open()
    if buf and vim.api.nvim_buf_is_valid(buf) then
        -- buffer exists, reuse it
    else
        buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_call(buf, function()
            vim.fn.termopen(config.command, {
                on_exit = function()
                    buf = nil
                end,
            })
        end)
    end

    local width = math.floor(vim.o.columns * config.width)
    local height = math.floor(vim.o.lines * config.height)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        border = config.border,
        title = config.title,
        title_pos = "center",
        style = "minimal",
    })

    vim.api.nvim_win_set_option(win, "winhl", "Normal:SummonFloat,FloatBorder:SummonBorder,FloatTitle:SummonTitle")

    vim.cmd("startinsert")

    vim.keymap.set("t", config.close_keymap, function()
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, false)
        end
    end, { buffer = buf })
end

function M.setup(opts)
    config = vim.tbl_deep_extend("force", default_config, opts or {})

    vim.g.terminal_color_0 = config.highlights.float.bg or "#282828"

    set_highlights()

    if config.keymap then
        vim.keymap.set("n", config.keymap, M.open, { desc = "Summon floating terminal" })
    end
end

return M
