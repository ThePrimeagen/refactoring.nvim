local Path = require("plenary.path")

local M = {}
function M.read_file(file)
    return Path:new("lua", "refactoring", "tests", file):read()
end

function M.vim_motion(motion)
    vim.cmd(string.format(':exe "norm! %s\\<esc>"', motion))
end

function M.open_test_file(file)
    vim.cmd(":e  ./lua/refactoring/tests/" .. file)
    return vim.api.nvim_get_current_buf()
end

return M
