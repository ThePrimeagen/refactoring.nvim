local a = require("plenary.async").tests
local Path = require("plenary.path")
local debug = require("refactoring.debug")
local scandir = require("plenary.scandir")
local utils = require("refactoring.utils")
local test_utils = require("refactoring.tests.utils")
local async = require("plenary.async")
local Config = require("refactoring.config")

local cwd = vim.loop.cwd()
vim.cmd("set rtp+=" .. cwd)
local eq = assert.are.same

local function remove_cwd(file)
    return file:sub(#cwd + 2 + #"lua/refactoring/tests/")
end

-- TODO: Move this to utils
local function for_each_file(cb)
    local files = scandir.scan_dir(
        Path:new(cwd, "lua", "refactoring", "tests", "debug"):absolute()
    )
    for _, file in pairs(files) do
        file = remove_cwd(file)
        if string.match(file, "start") then
            cb(file)
        end
    end
end

describe("Debug", function()
    for_each_file(function(file)
        a.it(string.format("printf: %s", file), function()
            local parts = utils.split_string(file, "%.")
            local filename_prefix = parts[1]
            local filename_extension = parts[3]

            local bufnr = test_utils.open_test_file(file)
            local expected = test_utils.get_contents(
                string.format(
                    "%s.expected.%s",
                    filename_prefix,
                    filename_extension
                )
            )

            test_utils.run_inputs_if_exist(filename_prefix, cwd)
            test_utils.run_commands(filename_prefix)
            Config.get():set_test_bufnr(bufnr)

            debug["printf"]({})
            async.util.scheduler()
            local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
            eq(expected, lines)
        end)
    end)
end)
