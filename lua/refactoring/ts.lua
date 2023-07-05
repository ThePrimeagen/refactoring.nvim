local ts_locals = require("nvim-treesitter.locals")

local M = {}

---@return TSNode|nil
M.get_node_at_cursor = function()
    return vim.treesitter.get_node()
end

---@param node TSNode
---@param bufnr integer
---@return TSNode, TSNode
M.find_definition = function(node, bufnr)
    return ts_locals.find_definition(node, bufnr)
end

---@param node TSNode
---@param scope TSNode|nil
---@param bufnr integer
---@param definition TSNode|nil
---@return TSNode[]
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

return M
