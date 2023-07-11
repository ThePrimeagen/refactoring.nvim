local Path = require("plenary.path")
local Config = require("refactoring.config")
local utils = require("refactoring.utils")

local M = {}

---@param file string
---@return string
function M.read_file(file)
    return Path:new("lua", "refactoring", "tests", file):read()
end

---@param motion string
function M.vim_motion(motion)
    vim.cmd(string.format(':exe "norm! %s\\<esc>"', motion))
end

---@param file string
---@return string[]
function M.get_contents(file)
    return utils.split_string(M.read_file(file), "\n")
end

---@param filename_prefix string
---@param cwd string
function M.run_inputs_if_exist(filename_prefix, cwd)
    local input_file_name = string.format("%s.inputs", filename_prefix)
    local inputs_file =
        Path:new(cwd, "lua", "refactoring", "tests", input_file_name)
    if inputs_file:exists() then
        local inputs =
            M.get_contents(string.format("%s.inputs", filename_prefix))
        Config.get():automate_input(inputs)
    end
end

---@param filename_prefix string
---@return string[]
local function get_commands(filename_prefix)
    return utils.split_string(
        M.read_file(string.format("%s.commands", filename_prefix)),
        "\n"
    )
end

---@param filename_prefix string
function M.run_commands(filename_prefix)
    for _, command in pairs(get_commands(filename_prefix)) do
        vim.cmd(command)
    end
end

---@param file string
---@return integer bufnr
function M.open_test_file(file)
    vim.cmd(":e  ./lua/refactoring/tests/" .. file)
    return vim.api.nvim_get_current_buf()
end

---@param test_name string: test name to check if we should skip
---@param tests_to_skip string[]: table with names of tests that we want to skip
---@return boolean: return whether a test should be skipped if it's in table of tests to skip
function M.check_if_skip_test(test_name, tests_to_skip)
    for _, test in pairs(tests_to_skip) do
        if test_name == test then
            return true
        end
    end
    return false
end

return M
