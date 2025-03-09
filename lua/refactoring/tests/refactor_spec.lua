local a = require("plenary.async").tests
local describe = a.describe
local Path = require("plenary.path")
local scandir = require("plenary.scandir")
local refactoring = require("refactoring")
local Config = require("refactoring.config")
local test_utils = require("refactoring.tests.utils")

local async = require("plenary.async")

---@type table<string, ft>
local extension_to_filetype = {
    ["lua"] = "lua",
    ["ts"] = "typescript",
    ["tsx"] = "typescriptreact",
    ["js"] = "javascript",
    ["go"] = "go",
    ["py"] = "python",
    ["java"] = "java",
    ["ruby"] = "ruby",
    ["rb"] = "ruby",
    ["c"] = "c",
    ["cpp"] = "cpp",
    ["php"] = "php",
}

local tests_to_skip = {}

local cwd = vim.uv.cwd() --[[@as string]]
vim.cmd("set rtp+=" .. cwd)

local eq = assert.are.same

---@param file string
---@return string
local function remove_cwd(file)
    return file:sub(#cwd + 2 + #"lua/refactoring/tests/")
end

---@param cb fun(file: string)
local function for_each_file(cb)
    local files = scandir.scan_dir(
        Path:new(cwd, "lua", "refactoring", "tests", "refactor"):absolute()
    ) --[=[@as string[]]=]
    test_utils.for_each_file(files, cwd, cb, function(file)
        return not test_utils.check_if_skip_test(file, tests_to_skip)
    end)
end

local function test_empty_input()
    local test_cases = {
        [1] = {
            ["inputs"] = "",
            ["file"] = "refactor/106/lua/simple-function/extract.start.lua",
            ["error_message"] = "Error: Must provide function name",
        },
        [2] = {
            ["inputs"] = "",
            ["file"] = "refactor/119/ts/example/extract_var.start.ts",
            ["error_message"] = "Error: Must provide new var name",
        },
    }

    for _, test_case in ipairs(test_cases) do
        local file = Path
            :new(cwd, "lua", "refactoring", "tests", test_case["file"])
            :absolute() --[[@as string]]
        file = remove_cwd(file)
        local parts = vim.split(file, ".", { plain = true, trimempty = true })
        local filename_prefix = parts[1]
        local filename_extension = parts[3]
        local path_split = vim.split(parts[1], "/", { trimempty = true })
        local refactor = path_split[#path_split]

        local bufnr = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_win_set_buf(0, bufnr)
        vim.bo[bufnr].filetype = extension_to_filetype[filename_extension]
        vim.api.nvim_buf_set_lines(
            bufnr,
            0,
            -1,
            false,
            test_utils.get_contents(file)
        )
        Config.get():automate_input(test_case["inputs"])

        test_utils.run_commands(filename_prefix)

        local keys = refactoring.refactor(refactor)
        local status, err = pcall(vim.cmd.normal, keys) ---@type boolean, string

        vim.api.nvim_buf_delete(bufnr, { force = true })

        eq(false, status)

        local has_error_message = (err):find(test_case["error_message"])
        if not has_error_message then
            eq(test_case["error_message"], err)
        end
    end
end

---@param ok boolean
---@param err string|nil
---@param filename_prefix string
local function validate_error_if_file_exists(ok, err, filename_prefix)
    local expected_error_name = ("%s.expected_error"):format(filename_prefix)
    local expected_error_file =
        Path:new(cwd, "lua", "refactoring", "tests", expected_error_name)

    assert.are.same(expected_error_file:exists(), not ok)

    if err and err ~= "" and not expected_error_file:exists() then
        error(err)
    elseif not expected_error_file:exists() or not err then
        return
    end
    local error =
        test_utils.get_contents(("%s.expected_error"):format(filename_prefix))
    local expected_error = error[1]
    local has_error_message = (err):find(expected_error)
    if not has_error_message then
        eq(expected_error, err)
    end
end

---@param filename_prefix string
local function validate_cursor_if_file_exists(filename_prefix)
    local cursor_position_name = ("%s.cursor_position"):format(filename_prefix)
    local cursor_position_file =
        Path:new(cwd, "lua", "refactoring", "tests", cursor_position_name)
    if not cursor_position_file:exists() then
        return
    end

    local cursor_position =
        test_utils.get_contents(("%s.cursor_position"):format(filename_prefix))
    local expected_row = tonumber(cursor_position[1])
    local expected_col = tonumber(cursor_position[2])

    local cursor = vim.api.nvim_win_get_cursor(0)
    local result_row = cursor[1]
    local result_col = cursor[2]
    assert(
        expected_row == result_row,
        ("cursor row invalid, expected %s got %s"):format(
            expected_row,
            result_row
        )
    )
    assert(
        expected_col == result_col,
        ("cursor col invalid, expected %s got %s"):format(
            expected_col,
            result_col
        )
    )
end

-- TODO: make this better for more complex config options
-- assuming first line is for prompt_func_return_type flag
---@param filename_prefix string
---@param filename_extension string
local function set_config_options(filename_prefix, filename_extension)
    local config_file_name = ("%s.config"):format(filename_prefix)
    local config_file =
        Path:new(cwd, "lua", "refactoring", "tests", config_file_name)
    if config_file:exists() then
        local config_values =
            test_utils.get_contents(("%s.config"):format(filename_prefix))

        --- @type table<string, boolean>
        local prompt_func_return_type = {}
        local str_to_bool = { ["true"] = true, ["false"] = false }
        prompt_func_return_type[filename_extension] =
            str_to_bool[config_values[1]]
        Config.get():set_prompt_func_return_type(prompt_func_return_type)

        --- @type table<string, boolean>
        local prompt_func_param_type = {}
        prompt_func_param_type[filename_extension] =
            str_to_bool[config_values[2]]
        Config.get():set_prompt_func_param_type(prompt_func_param_type)

        if config_values[3] ~= nil then
            local extract_var_statement = config_values[3]
            Config.get():set_extract_var_statement(
                extension_to_filetype[filename_extension],
                extract_var_statement
            )
        end
    end
end

local function buf_setlocal_options(filename_extension)
    if filename_extension == "java" then
        vim.cmd([[setlocal shiftwidth=4]])
    elseif filename_extension == "go" then
        vim.cmd([[setlocal shiftwidth=4 expandtab]])
    elseif filename_extension == "cpp" or filename_extension == "c" then
        vim.cmd([[setlocal shiftwidth=2]])
    end
end

describe("Refactoring", function()
    vim.notify = error

    for_each_file(function(file)
        a.it(("Refactoring: %s"):format(file), function()
            local parts =
                vim.split(file, ".", { plain = true, trimempty = true })
            local filename_prefix = parts[1]
            local filename_extension = parts[3]
            local path_split = vim.split(parts[1], "/", { trimempty = true })
            local refactor = path_split[#path_split]

            local bufnr = test_utils.open_test_file(file)
            local expected = test_utils.get_contents(
                ("%s.expected.%s"):format(filename_prefix, filename_extension)
            )

            Config.get():reset()

            set_config_options(filename_prefix, filename_extension)
            test_utils.run_inputs_if_exist(filename_prefix, cwd)

            -- Needed for local testing
            buf_setlocal_options(filename_extension)

            test_utils.run_commands(filename_prefix)
            local keys = refactoring.refactor(refactor)
            local ok, err = pcall(vim.cmd.normal, keys) ---@type boolean, string

            validate_error_if_file_exists(ok, err, filename_prefix)

            async.util.scheduler()
            local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

            eq(expected, lines)
            validate_cursor_if_file_exists(filename_prefix)
        end)
    end)

    a.it("Refactoring: empty input", function()
        test_empty_input()
    end)
end)
