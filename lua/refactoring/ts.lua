local ts_locals = require("nvim-treesitter.locals")
local ts_utils = require("nvim-treesitter.ts_utils")

local M = {}

M.get_node_at_cursor = function(win)
    return ts_utils.get_node_at_cursor(win)
end

M.find_definition = function(node, bufnr)
    return ts_locals.find_definition(node, bufnr)
end

M.find_references = function(node, scope, bufnr, definition)
    if not definition then
        definition = M.find_definition(node, bufnr)
    end

    local references = {}
    for _, ref in ipairs(ts_locals.find_usages(node, scope, bufnr)) do
        if ref ~= definition then
            table.insert(references, ref)
        end
    end

    return references
end

M.get_node_text = function(node, bufnr, sep)
    sep = sep or " "

    return table.concat(ts_utils.get_node_text(node, bufnr), sep)
end

return M
