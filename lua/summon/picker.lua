local M = {}

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

    local entries = {}
    local entry_to_name = {}
    for _, name in ipairs(names) do
        local entry = format_entry(name, commands)
        table.insert(entries, entry)
        entry_to_name[entry] = name
    end

    fzf.fzf_exec(entries, {
        prompt = "Summon> ",
        actions = {
            ["default"] = function(selected)
                if selected and selected[1] then
                    local name = entry_to_name[selected[1]]
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
