vim.api.nvim_create_user_command("Summon", function()
    require("summon").open()
end, { desc = "Open Summon floating terminal" })
