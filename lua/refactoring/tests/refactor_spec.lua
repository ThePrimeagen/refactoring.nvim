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

            local contents = test_utils.split_string(
                test_utils.read_file(file),
                "\n"
            )
            local inputs = test_utils.split_string(
                test_utils.read_file(
                    string.format("%s.%s.inputs", parts[1], parts[2])
                ),
                "\n"
            )
            local commands = test_utils.split_string(
                test_utils.read_file(
                    string.format(
                        "%s.%s.%s.commands",
                        parts[1],
                        parts[2],
                        parts[4]
                    )
                ),
                "\n"
            )
            local expected = test_utils.split_string(
                test_utils.read_file(
                    string.format(
                        "%s.%s.expected.%s",
                        parts[1],
                        parts[2],
                        parts[4]
                    )
                ),
                "\n"
            )

            vim.cmd(":new")
            vim.cmd(
                string.format(
                    ":set filetype=%s",
                    extension_to_filetype[parts[4]]
                )
            )
            vim.api.nvim_buf_set_lines(0, 0, -1, false, contents)
            Config.automate_input(inputs)

            for _, command in pairs(commands) do
                vim.cmd(command)
            end

            refactoring[parts[1]](0)

            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            eq(expected, lines)
        end)
    end)
end)
