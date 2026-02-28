local M = {}

-- ANSI SGR escape codes for fzf --ansi rendering
local ansi = {
    reset = "\27[0m",
    bold = "\27[1m",
    dim = "\27[2m",
    white = "\27[37m",
    grey = "\27[90m",
    cyan = "\27[36m",
    green = "\27[32m",
    blue = "\27[34m",
    magenta = "\27[35m",
}

---@param cmd_type string
---@return string
local function type_label(cmd_type)
    if cmd_type == "file" then
        return ansi.blue .. "[file]" .. ansi.reset
    elseif cmd_type == "project_file" then
        return ansi.magenta .. "[proj]" .. ansi.reset
    end
    return ansi.green .. "[term]" .. ansi.reset
end

---@param names string[]
---@param commands table<string, table>
---@return { name: number, title: number, keymap: number }
local function compute_column_widths(names, commands)
    local w = { name = 0, title = 0, keymap = 0 }
    for _, name in ipairs(names) do
        local cmd = commands[name]
        w.name = math.max(w.name, #name)
        w.title = math.max(w.title, #(cmd.title or ""))
        w.keymap = math.max(w.keymap, #(cmd.keymap or ""))
    end
    return w
end

---@param name string
---@param commands table<string, table>
---@param widths { name: number, title: number, keymap: number }
---@return string
local function format_fzf_entry(name, commands, widths)
    local cmd = commands[name]
    local cmd_type = cmd.type or "terminal"
    local title = cmd.title or ""
    local keymap = cmd.keymap or ""
    local command = cmd.command or cmd.cmd or ""

    local display = type_label(cmd_type)
        .. " "
        .. ansi.bold
        .. ansi.white
        .. name
        .. ansi.reset
        .. string.rep(" ", widths.name - #name + 2)
        .. ansi.dim
        .. title
        .. ansi.reset
        .. string.rep(" ", widths.title - #title + 2)
        .. ansi.cyan
        .. keymap
        .. ansi.reset
        .. string.rep(" ", widths.keymap - #keymap + 2)
        .. ansi.grey
        .. command
        .. ansi.reset

    return name .. "\t" .. display
end

---@param name string
---@param commands table<string, table>
local function format_entry(name, commands)
    local cmd = commands[name]
    local parts = { name }
    if cmd.title then
        table.insert(parts, cmd.title)
    end
    local cmd_type = cmd.type or "terminal"
    if cmd_type ~= "terminal" then
        table.insert(parts, "[" .. cmd_type .. "]")
    end
    return table.concat(parts, "  ")
end

---@param names string[]
---@param commands table<string, table>
---@param on_choice fun(name: string)
local function pick_fzf(names, commands, on_choice)
    local fzf = require("fzf-lua")

    local widths = compute_column_widths(names, commands)
    local entries = {}
    for _, name in ipairs(names) do
        table.insert(entries, format_fzf_entry(name, commands, widths))
    end

    fzf.fzf_exec(entries, {
        prompt = "Summon> ",
        fzf_opts = {
            ["--ansi"] = "",
            ["--delimiter"] = "\t",
            ["--with-nth"] = "2..",
        },
        actions = {
            ["default"] = function(selected)
                if selected and selected[1] then
                    local name = selected[1]:match("^([^\t]+)")
                    if name then
                        on_choice(name)
                    end
                end
            end,
        },
    })
end

---@param names string[]
---@param commands table<string, table>
---@param on_choice fun(name: string)
local function pick_vim(names, commands, on_choice)
    vim.ui.select(names, {
        prompt = "Summon",
        format_item = function(name)
            return format_entry(name, commands)
        end,
    }, function(choice)
        if choice then
            on_choice(choice)
        end
    end)
end

local backends = {
    fzf = pick_fzf,
    vim = pick_vim,
}

---@param names string[]
---@param commands table<string, table>
---@param on_choice fun(name: string)
---@param picker_opt string|nil
function M.pick(names, commands, on_choice, picker_opt)
    local backend = picker_opt or "auto"

    if backend == "auto" then
        local ok = pcall(require, "fzf-lua")
        backend = ok and "fzf" or "vim"
    end

    local fn = backends[backend]
    if not fn then
        vim.notify("summon.nvim: unknown picker " .. tostring(backend), vim.log.levels.WARN)
        fn = pick_vim
    end

    fn(names, commands, on_choice)
end

return M
