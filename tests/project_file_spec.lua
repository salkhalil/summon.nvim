local summon = require("summon")

local function eq(actual, expected, message)
    assert.are.same(expected, actual, message)
end

local function truthy(value, message)
    assert.is_true(value, message)
end

local function make_temp_dir()
    local path = vim.fn.tempname()
    vim.fn.mkdir(path, "p")
    return path
end

local function write_file(path, lines)
    local parent = vim.fs.dirname(path)
    if parent and parent ~= "" then
        vim.fn.mkdir(parent, "p")
    end

    vim.fn.writefile(lines or {}, path)
end

local function close_float_if_needed()
    local config = vim.api.nvim_win_get_config(0)
    if config.relative and config.relative ~= "" then
        vim.api.nvim_win_close(0, false)
    end
end

local function reset_to_file(path)
    close_float_if_needed()
    vim.cmd("edit " .. vim.fn.fnameescape(path))
end

local function current_buffer_path()
    local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p")
    return vim.uv.fs_realpath(path) or path
end

local function normalize_path(path)
    local expanded = vim.fn.fnamemodify(path, ":p")
    return vim.uv.fs_realpath(expanded) or expanded
end

describe("project_file command", function()
    local original_cwd
    local workspace
    local repo_root
    local nested_dir
    local package_root
    local package_nested
    local plain_root
    local plain_nested
    local repo_b_root
    local repo_b_nested

    before_each(function()
        original_cwd = vim.fn.getcwd()
        workspace = make_temp_dir()

        repo_root = vim.fs.joinpath(workspace, "repo")
        nested_dir = vim.fs.joinpath(repo_root, "lua", "feature")
        vim.fn.mkdir(vim.fs.joinpath(repo_root, ".git"), "p")
        write_file(vim.fs.joinpath(nested_dir, "init.lua"), { "return true" })

        package_root = vim.fs.joinpath(workspace, "pkg")
        package_nested = vim.fs.joinpath(package_root, "src", "deep")
        write_file(vim.fs.joinpath(package_root, "package.json"), { "{}" })
        write_file(vim.fs.joinpath(package_nested, "index.lua"), { "return true" })

        plain_root = vim.fs.joinpath(workspace, "plain")
        plain_nested = vim.fs.joinpath(plain_root, "notes")
        write_file(vim.fs.joinpath(plain_nested, "scratch.lua"), { "return true" })

        repo_b_root = vim.fs.joinpath(workspace, "repo_b")
        repo_b_nested = vim.fs.joinpath(repo_b_root, "app")
        vim.fn.mkdir(vim.fs.joinpath(repo_b_root, ".git"), "p")
        write_file(vim.fs.joinpath(repo_b_nested, "main.lua"), { "return true" })

        summon.setup({
            commands = {
                project_notes = {
                    type = "project_file",
                    command = ".summon/notes.md",
                    filetype = "markdown",
                },
                package_notes = {
                    type = "project_file",
                    command = ".summon/package-notes.md",
                    root_pattern = "package.json",
                },
            },
        })
    end)

    after_each(function()
        close_float_if_needed()
        vim.cmd("cd " .. vim.fn.fnameescape(original_cwd))
        vim.cmd("silent! %bwipeout!")
    end)

    it("uses the nearest .git root", function()
        reset_to_file(vim.fs.joinpath(nested_dir, "init.lua"))
        summon.open("project_notes")

        local expected = normalize_path(vim.fs.joinpath(repo_root, ".summon", "notes.md"))
        eq(current_buffer_path(), expected, "project_file should resolve to the nearest .git root")
        truthy(vim.fn.filereadable(expected) == 1, "project_file should create the target file")
        eq(vim.bo.filetype, "markdown", "project_file should apply filetype overrides")
    end)

    it("supports custom root_pattern", function()
        reset_to_file(vim.fs.joinpath(package_nested, "index.lua"))
        summon.open("package_notes")

        local expected = normalize_path(vim.fs.joinpath(package_root, ".summon", "package-notes.md"))
        eq(current_buffer_path(), expected, "project_file should use the configured root_pattern")
        truthy(vim.fn.filereadable(expected) == 1, "project_file should create custom-root files")
    end)

    it("falls back to cwd when no marker exists", function()
        reset_to_file(vim.fs.joinpath(plain_nested, "scratch.lua"))
        vim.cmd("cd " .. vim.fn.fnameescape(plain_root))
        summon.open("project_notes")

        local expected = normalize_path(vim.fs.joinpath(plain_root, ".summon", "notes.md"))
        eq(current_buffer_path(), expected, "project_file should fall back to cwd when no marker is found")
        truthy(vim.fn.filereadable(expected) == 1, "project_file should create fallback files")
    end)

    it("caches by resolved path", function()
        reset_to_file(vim.fs.joinpath(nested_dir, "init.lua"))
        summon.open("project_notes")
        local first = current_buffer_path()

        close_float_if_needed()
        reset_to_file(vim.fs.joinpath(repo_b_nested, "main.lua"))
        summon.open("project_notes")
        local second = current_buffer_path()

        local expected_first = normalize_path(vim.fs.joinpath(repo_root, ".summon", "notes.md"))
        local expected_second = normalize_path(vim.fs.joinpath(repo_b_root, ".summon", "notes.md"))

        eq(first, expected_first, "first project_file open should target repo A")
        eq(second, expected_second, "second project_file open should target repo B")
        assert.are_not.same(first, second, "project_file buffers should not be reused across different roots")
    end)
end)
