vim.api.nvim_create_user_command("Summon", function(opts)
    local name = opts.args
    if name == "" then
        -- Default to first command if only one is configured
        local summon = require("summon")
        local commands = summon._get_commands()
        local names = vim.tbl_keys(commands)
        if #names == 1 then
            summon.open(names[1])
        else
            vim.notify("Summon: specify a command name — " .. table.concat(names, ", "), vim.log.levels.WARN)
        end
        return
    end
    require("summon").open(name)
end, {
    nargs = "?",
    complete = function()
        local commands = require("summon")._get_commands()
        return vim.tbl_keys(commands)
    end,
    desc = "Open Summon floating terminal",
})
