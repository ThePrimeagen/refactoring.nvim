local Region = require("refactoring.region")
local ts_locals = require("refactoring.ts-locals")

---@param refactor Refactor
local function node_on_cursor_setup(refactor)
    local identifier_node = vim.treesitter.get_node()

    if identifier_node == nil then
        return false, "Identifier_node is nil"
    end

    local scope =
        ts_locals.containing_scope(identifier_node, refactor.bufnr, false)

    if scope == nil then
        return false, "Scope is nil"
    end

    local declarator_node =
        refactor.ts.get_container(identifier_node, refactor.ts.variable_scope)

    if declarator_node == nil then
        return false, "containing_statement is nil"
    end

    refactor.region = Region:from_node(declarator_node)
    refactor.identifier_node = identifier_node
    refactor.region_node = declarator_node
    refactor.scope = scope

    return true, refactor
end

return node_on_cursor_setup
