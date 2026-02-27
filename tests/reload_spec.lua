local summon = require("summon")

local function close_float_if_needed()
    local config = vim.api.nvim_win_get_config(0)
    if config.relative and config.relative ~= "" then
        vim.api.nvim_win_close(0, true)
    end
end

describe("reload option", function()
    after_each(function()
        close_float_if_needed()
        vim.cmd("silent! %bwipeout!")
    end)

    it("creates a fresh buffer each time when reload = true", function()
        summon.setup({
            commands = {
                echo_test = {
                    type = "terminal",
                    command = "echo hello",
                    reload = true,
                },
            },
        })

        summon.open("echo_test")
        local buf1 = vim.api.nvim_get_current_buf()
        close_float_if_needed()

        summon.open("echo_test")
        local buf2 = vim.api.nvim_get_current_buf()

        assert.are_not.equal(buf1, buf2, "reload = true should create a new buffer each time")
    end)

    it("reuses the same buffer when reload is not set", function()
        summon.setup({
            commands = {
                persist_test = {
                    type = "terminal",
                    command = "echo hello",
                },
            },
        })

        summon.open("persist_test")
        local buf1 = vim.api.nvim_get_current_buf()
        close_float_if_needed()

        summon.open("persist_test")
        local buf2 = vim.api.nvim_get_current_buf()

        assert.are.equal(buf1, buf2, "without reload, the same buffer should be reused")
    end)

    it("warns when reload is not a boolean", function()
        local warnings = {}
        local original_notify = vim.notify
        vim.notify = function(msg, level)
            if level == vim.log.levels.WARN then
                table.insert(warnings, msg)
            end
        end

        summon.setup({
            commands = {
                bad_reload = {
                    type = "terminal",
                    command = "echo hello",
                    reload = "yes",
                },
            },
        })

        vim.notify = original_notify

        local found = false
        for _, msg in ipairs(warnings) do
            if msg:match("reload") and msg:match("boolean") then
                found = true
                break
            end
        end

        assert.is_true(found, "should warn when reload is not a boolean")
    end)
end)
