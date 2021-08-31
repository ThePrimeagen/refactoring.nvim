local Path = require("plenary.path")
local lsp_utils = require("refactoring.lsp_utils")

local M = {}
function M.read_file(file)
    return Path:new("lua", "refactoring", "tests", file):read()
end

function M.vim_motion(motion)
    vim.cmd(string.format(':exe "norm! %s\\<esc>"', motion))
end

function M.split_string(inputstr, sep)
    local t = {}
    -- [[ lets not think about the edge case there... --]]
    while #inputstr > 0 do
        local start, stop = inputstr:find(sep)
        local str
        if not start then
            str = inputstr
            inputstr = ""
        else
            str = inputstr:sub(1, start - 1)
            inputstr = inputstr:sub(stop + 1)
        end
        table.insert(t, str)
    end
    return t
end

function M.get_references_under_cursor(bufnr, definition_region)
    local references
    vim.wait(10000, function()
        -- TODO: why cant i pcall this?
        references = lsp_utils.get_references_under_cursor(
            bufnr,
            definition_region
        )
        return references
    end)
    return references
end

function M.get_definition_under_cursor(bufnr)
    local definition
    vim.wait(4000, function()
        local ok, value = pcall(lsp_utils.get_definition_under_cursor, bufnr)
        definition = value
        return ok
    end)
    return definition
end

return M
