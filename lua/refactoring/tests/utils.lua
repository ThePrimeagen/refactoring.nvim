local Path = require("plenary.path")
local Config = require("refactoring.config")
local utils = require("refactoring.utils")

local M = {}
function M.read_file(file)
    return Path:new("lua", "refactoring", "tests", file):read()
end

function M.vim_motion(motion)
    vim.cmd(string.format(':exe "norm! %s\\<esc>"', motion))
end

function M.get_contents(file)
    return utils.split_string(M.read_file(file), "\n")
end

function M.run_inputs_if_exist(filename_prefix, cwd)
    local input_file_name = string.format("%s.inputs", filename_prefix)
    local inputs_file = Path:new(
        cwd,
        "lua",
        "refactoring",
        "tests",
        input_file_name
    )
    if inputs_file:exists() then
        print("M.run_inputs_if_exist#if") -- __AUTO_GENERATED_PRINTF__
        local inputs = M.get_contents(
            string.format("%s.inputs", filename_prefix)
        )
        Config.get():automate_input(inputs)
    end
end

local function get_commands(filename_prefix)
    return utils.split_string(
        M.read_file(string.format("%s.commands", filename_prefix)),
        "\n"
    )
end

function M.run_commands(filename_prefix)
    for _, command in pairs(get_commands(filename_prefix)) do
        vim.cmd(command)
    end
end

function M.open_test_file(file)
    vim.cmd(":e  ./lua/refactoring/tests/" .. file)
    return vim.api.nvim_get_current_buf()
end

return M
