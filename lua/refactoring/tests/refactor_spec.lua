local Path = require("plenary.path")
local scandir = require("plenary.scandir")
local refactoring = require("refactoring.refactor")
local Config = require("refactoring.config")
local test_utils = require("refactoring.tests.utils")

local cwd = vim.loop.cwd()
vim.cmd("set rtp+=" .. cwd)

local eq = assert.are.same

local function remove_cwd(file)
    return file:sub(#cwd + 2 + #"lua/refactoring/tests/")
end

local extension_to_filetype = {
    ["lua"] = "lua",
    ["ts"] = "typescript",
    ["go"] = "go",
    ["py"] = "python",
}

local function for_each_file(cb)
    local files = scandir.scan_dir(
        Path:new(cwd, "lua", "refactoring", "tests"):absolute()
    )
    for _, file in pairs(files) do
        file = remove_cwd(file)
        if string.match(file, "start") then
            cb(file)
        end
    end
end

local function get_commands(parts)
    return test_utils.split_string(
        test_utils.read_file(
            string.format("%s.%s.%s.commands", parts[1], parts[2], parts[4])
        ),
        "\n"
    )
end

local function get_contents(file)
    return test_utils.split_string(test_utils.read_file(file), "\n")
end

local function run_commands(parts)
    for _, command in pairs(get_commands(parts)) do
        vim.cmd(command)
    end
end

local function test_empty_input()
    local test_cases = {
        [1] = {
            ["inputs"] = "",
            ["file"] = "extract.simple-function.start.lua",
            ["refactor_func"] = "extract",
            ["error_message"] = "Error: Must provide function name",
        },
        [2] = {
            ["inputs"] = "",
            ["file"] = "extract_var.example.start.ts",
            ["refactor_func"] = "extract_var",
            ["error_message"] = "Error: Must provide new var name",
        },
    }

    for _, test_case in ipairs(test_cases) do
        local file = Path
            :new(cwd, "lua", "refactoring", "tests", test_case["file"])
            :absolute()
        file = remove_cwd(file)
        local parts = test_utils.split_string(file, "%.")

        local bufnr = vim.api.nvim_create_buf(false, false)
        vim.api.nvim_win_set_buf(0, bufnr)
        vim.bo[bufnr].filetype = extension_to_filetype[parts[4]]
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, get_contents(file))
        Config.automate_input(test_case["inputs"])

        run_commands(parts)

        local status, err = pcall(
            refactoring[test_case["refactor_func"]],
            bufnr
        )

        -- Need this for make file so that next test has clean buffer
        vim.api.nvim_buf_delete(bufnr, { force = true })

        eq(false, status)
        -- TODO: find a better way to validate errors
        assert(string.find(err, test_case["error_message"]) > 0)
    end
end

describe("Refactoring", function()
    for_each_file(function(file)
        it(string.format("Refactoring: %s", file), function()
            local parts = test_utils.split_string(file, "%.")

            if not refactoring[parts[1]] then
                error(
                    string.format(
                        "malformed test file: expected %s to be a valid refactor",
                        refactoring[parts[1]]
                    )
                )
            end

            local start_contents = get_contents(file)
            local inputs = get_contents(
                string.format("%s.%s.inputs", parts[1], parts[2])
            )
            local expected = get_contents(
                string.format("%s.%s.expected.%s", parts[1], parts[2], parts[4])
            )

            local bufnr = vim.api.nvim_create_buf(false, false)
            vim.api.nvim_win_set_buf(0, bufnr)
            vim.bo[bufnr].filetype = extension_to_filetype[parts[4]]
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, start_contents)
            Config.automate_input(inputs)

            run_commands(parts)

            refactoring[parts[1]](bufnr)

            local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

            -- Need this for make file so that next test has clean buffer
            vim.api.nvim_buf_delete(bufnr, { force = true })

            eq(expected, lines)
        end)
    end)

    it("Refactoring: empty input", function()
        test_empty_input()
    end)
end)
