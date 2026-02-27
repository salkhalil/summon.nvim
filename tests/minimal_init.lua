vim.o.swapfile = false
vim.o.shadafile = "NONE"

vim.opt.runtimepath:append(vim.fn.getcwd())

local plenary_path = vim.env.PLENARY_PATH
if (not plenary_path or plenary_path == "") then
    local lazy_plenary = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy", "plenary.nvim")
    if vim.fn.isdirectory(lazy_plenary) == 1 then
        plenary_path = lazy_plenary
    end
end

if plenary_path and plenary_path ~= "" then
    vim.opt.runtimepath:append(plenary_path)
end

pcall(vim.cmd, "packadd plenary.nvim")
pcall(vim.cmd, "packadd plenary")
