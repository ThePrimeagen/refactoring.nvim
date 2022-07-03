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

-- TODO: make this better for more complex config options
-- assuming first line is for a custom printf statement
-- and second line is for a custom print var statement
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

        if config_values[1] ~= "" then
            local filetypes = {
                ["ts"] = "typescript",
                ["js"] = "javascript",
                ["py"] = "python",
                ["rb"] = "ruby",
            }

            -- get the real filetype from the above table if possible
            local real_filetype = filetypes[filename_extension]
                or filename_extension

            local printf_statements = {}
            printf_statements[real_filetype] = { config_values[1] }
            Config:get():set_printf_statements(printf_statements)

            local print_var_statements = {}
            print_var_statements[real_filetype] = { config_values[1] }
            Config:get():set_print_var_statements(print_var_statements)
        end
    end
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

local function get_debug_operation(path)
    local temp = {}
    local index = 1
    for i in string.gmatch(path, "([^/]+)") do
        table.insert(temp, index, i)
        index = index + 1
    end
    return temp[#temp]
end

local function get_func_opts(filename_prefix)
    local opts_file_name = string.format("%s.opts", filename_prefix)

    local opts_file = Path:new(
        cwd,
        "lua",
        "refactoring",
        "tests",
        opts_file_name
    )

    local opts = {}
    if opts_file:exists() then
        local opts_values = test_utils.get_contents(opts_file_name)

        if opts_values[1] ~= nil then
            opts["normal"] = true
        end
    end

    return opts
end

describe("Debug", function()
    for_each_file(function(file)
        a.it(string.format("printf: %s", file), function()
            local parts = utils.split_string(file, "%.")
            local filename_prefix = parts[1]
            local filename_extension = parts[3]
            local debug_operation = get_debug_operation(filename_prefix)

            local bufnr = test_utils.open_test_file(file)
            local expected = test_utils.get_contents(
                string.format(
                    "%s.expected.%s",
                    filename_prefix,
                    filename_extension
                )
            )

            Config:get():reset()

            set_config_options(filename_prefix, filename_extension)

            test_utils.run_inputs_if_exist(filename_prefix, cwd)
            test_utils.run_commands(filename_prefix)
            Config.get():set_test_bufnr(bufnr)

            local func_opts = get_func_opts(filename_prefix)

            debug[debug_operation](func_opts)
            async.util.scheduler()
            local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
            eq(expected, lines)
        end)
    end)
end)
