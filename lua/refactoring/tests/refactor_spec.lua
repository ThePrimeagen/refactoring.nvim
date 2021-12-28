local a = require("plenary.async").tests
local describe = a.describe
local Path = require("plenary.path")
local scandir = require("plenary.scandir")
local refactoring = require("refactoring")
local Config = require("refactoring.config")
local test_utils = require("refactoring.tests.utils")
local utils = require("refactoring.utils")

local async = require("plenary.async")

local extension_to_filetype = {
    ["lua"] = "lua",
    ["ts"] = "typescript",
    ["js"] = "javascript",
    ["go"] = "go",
    ["py"] = "python",
}

local refactor_id_to_refactor = {
    ["119"] = { name = "extract_var" },
    ["106"] = { name = "extract" },
    ["123"] = { name = "inline_var" },
}

local cwd = vim.loop.cwd()
vim.cmd("set rtp+=" .. cwd)

local eq = assert.are.same

local function remove_cwd(file)
    return file:sub(#cwd + 2 + #"lua/refactoring/tests/")
end

local function get_refactor_name_from_path(path)
    local refactor_id = path:match("%d+")
    local refactor = refactor_id_to_refactor[tostring(refactor_id)]
    if not refactor then
        error(
            string.format(
                "malformed test structure: expected %s to contain a valid refactor id",
                path
            )
        )
    end
    return refactor
end

local function for_each_file(cb)
    local files = scandir.scan_dir(
        Path:new(cwd, "lua", "refactoring", "tests", "refactor"):absolute()
    )
    for _, file in pairs(files) do
        file = remove_cwd(file)
        if string.match(file, "start") then
            cb(file)
        end
    end
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
            :absolute()
        file = remove_cwd(file)
        local parts = utils.split_string(file, "%.")
        local filename_prefix = parts[1]
        local filename_extension = parts[3]
        local refactor = get_refactor_name_from_path(filename_prefix)

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

        local status, err = pcall(refactoring.refactor, refactor["name"])

        -- waits for the next frame for formatting to work.
        async.util.scheduler()

        vim.api.nvim_buf_delete(bufnr, { force = true })

        eq(false, status)

        -- TODO: find a better way to validate errors
        local has_error_message = string.find(err, test_case["error_message"])
        if not has_error_message then
            eq(test_case["error_message"], err)
        end
    end
end

local function validate_cursor_if_file_exists(filename_prefix)
    local cursor_position_name = string.format(
        "%s.cursor_position",
        filename_prefix
    )
    local cursor_position_file = Path:new(
        cwd,
        "lua",
        "refactoring",
        "tests",
        cursor_position_name
    )
    if cursor_position_file:exists() then
        local cursor_position = test_utils.get_contents(
            string.format("%s.cursor_position", filename_prefix)
        )
        local expected_row = tonumber(cursor_position[1])
        local expected_col = tonumber(cursor_position[2])

        local cursor = vim.api.nvim_win_get_cursor(0)
        local result_row = cursor[1]
        local result_col = cursor[2]
        assert(
            expected_row == result_row,
            string.format(
                "cursor row invalid, expected %s got %s",
                expected_row,
                result_row
            )
        )
        assert(
            expected_col == result_col,
            string.format(
                "cursor col invalid, expected %s got %s",
                expected_col,
                result_col
            )
        )
    end
end

-- TODO: make this better for more complex config options
-- assuming first line is for prompt_func_return_type flag
local function set_config_options(filename_prefix, filename_extension)
    local config_file_name = string.format("%s.config", filename_prefix)
    local config_file = Path:new(
        cwd,
        "lua",
        "refactoring",
        "tests",
        config_file_name
    )
    if config_file:exists() then
        local config_values = test_utils.get_contents(
            string.format("%s.config", filename_prefix)
        )
        local prompt_func_return_type = {}
        local str_to_bool = { ["true"] = true, ["false"] = false }
        prompt_func_return_type[filename_extension] =
            str_to_bool[config_values[1]]
        Config.get():set_prompt_func_return_type(prompt_func_return_type)
    end
end

describe("Refactoring", function()
    for_each_file(function(file)
        a.it(string.format("Refactoring: %s", file), function()
            local parts = utils.split_string(file, "%.")
            local filename_prefix = parts[1]
            local filename_extension = parts[3]
            local refactor = get_refactor_name_from_path(filename_prefix)

            local bufnr = test_utils.open_test_file(file)
            local expected = test_utils.get_contents(
                string.format(
                    "%s.expected.%s",
                    filename_prefix,
                    filename_extension
                )
            )

            Config.get():reset()
            test_utils.run_inputs_if_exist(filename_prefix, cwd)
            test_utils.run_commands(filename_prefix)
            -- TODO: How to get this dynamically?
            set_config_options(filename_prefix, filename_extension)
            refactoring.refactor(refactor["name"])
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
