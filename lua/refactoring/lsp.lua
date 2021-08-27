local utils = require("refactoring.utils")
local lsp_utils = require("refactoring.lsp_utils")
local Region = require("refactoring.region")
local Query = require("refactoring.query")

---@class LspDefinition
---@field value_node ts_node
---@field declarator_node ts_node
---@field definition lsp_range
---@field definition_region Region
local LspDefinition = {}
LspDefinition.__index = LspDefinition

function LspDefinition:from_cursor(bufnr, ts_query)
    local definition = lsp_utils.get_definition_under_cursor(bufnr)

    local definition_region = Region:from_lsp_range(
        definition.targetRange or definition.range
    )
    local declarator_node = ts_query:get_scope_over_region(
        definition_region,
        Query.query_type.Declarator
    )
    local value_node = ts_query:pluck_by_capture(
        declarator_node,
        Query.query_type.LocalVarValue
    )[1]
    if not value_node then
        error("Unable to find the value node of the local declarator")
    end

    return setmetatable({
        definition = definition,
        value_node = value_node,
        declarator_node = declarator_node,
        definition_region = definition_region,
    }, self)
end

function LspDefinition:get_declaration_region()
    return Region:from_node(self.declarator_node)
end

function LspDefinition:get_value_text()
    return table.concat(utils.get_node_text(self.value_node), "")
end

return LspDefinition
