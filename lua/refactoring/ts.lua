local ts_locals = require("nvim-treesitter.locals")
local ts_utils = require("nvim-treesitter.ts_utils")

local M = {}

---@param win integer
---@return TSNode
M.get_node_at_cursor = function(win)
    return ts_utils.get_node_at_cursor(win)
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

M.find_declaration = function(node, bufnr)
    local current_node_text = ts_utils.get_node_text(node, bufnr)[1]

    for _, definitions in ipairs(ts_locals.get_definitions(bufnr)) do
        for _, definition in pairs(definitions) do
            local def_node = definition.node

            -- TODO: not sure if this is the correct way to do it
            local texts = ts_utils.get_node_text(def_node, bufnr)
            local node_text = texts[1]
            if (node_text == current_node_text) then
                return def_node, true
            end
        end
    end
    -- TODO: return a default?? maybe
    return nil
end

return M
