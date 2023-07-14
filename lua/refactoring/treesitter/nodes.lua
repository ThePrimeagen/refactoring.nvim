local Query = require("refactoring.query")

local BaseFieldNode = {}
BaseFieldNode.__index = BaseFieldNode

---@param ... any
---@return any[]
local function to_array(...)
    local items = {}

    for idx = 1, select("#", ...) do
        local item = select(idx, ...)
        table.insert(items, item)
    end

    return items
end

---@class FieldnameNode
---@field fieldnames string[]
---@field node TSNode

---@alias FieldNodeFunc fun(node: TSNode, fallback: integer|string): FieldnameNode

---@param ... string
---@return FieldNodeFunc
local FieldNode = function(...)
    ---@type string[]
    local fieldnames = to_array(...)

    ---@param node TSNode
    ---@param fallback string
    ---@return FieldnameNode
    return function(node, fallback)
        return setmetatable({
            fieldnames = fieldnames,
            node = node,
        }, {
            __index = BaseFieldNode,

            ---@param self FieldnameNode
            ---@return string
            __tostring = function(self)
                if not self.node then
                    return fallback
                end

                local curr = self.node
                for idx = 1, #self.fieldnames do
                    --- @type TSNode[]
                    curr = curr:field(self.fieldnames[idx])

                    if not curr[1] then
                        return fallback
                    end
                    curr = curr[1]
                end

                return vim.treesitter.get_node_text(curr, 0) or fallback
            end,
        })
    end
end

---@param text string
---@return fun(): table
local StringNode = function(text)
    return function()
        return setmetatable({}, {
            __tostring = function()
                return text
            end,
        })
    end
end

---@alias InlineNodeFunc fun(scope: TSNode, bufnr: integer, filetype: string): TSNode[]

---@param sexpr string sexpr of a capture
---@return InlineNodeFunc
local InlineNode = function(sexpr)
    return function(scope, bufnr, filetype)
        local lang = vim.treesitter.language.get_lang(filetype)
        local ok, result_object = pcall(vim.treesitter.query.parse, lang, sexpr)
        if not ok then
            error(
                string.format(
                    "Invalid query: '%s'\n error: %s",
                    sexpr,
                    result_object
                )
            )
        end

        local out = {}
        for _, node, _ in result_object:iter_captures(scope, bufnr, 0, -1) do
            table.insert(out, node)
        end
        return out
    end
end

---@alias NodeFilter fun(id: integer, node: TSNode, query: Query): boolean
---@alias InlineFilteredNodeFunc fun(scope: TSNode, bufnr: integer, filetype: string, filter: NodeFilter): TSNode[]

---@param sexpr string sexpr with multiple captures
---@return InlineFilteredNodeFunc
local InlineFilteredNode = function(sexpr)
    return function(scope, bufnr, filetype, filter)
        local lang = vim.treesitter.language.get_lang(filetype)
        local ok, result_object = pcall(vim.treesitter.query.parse, lang, sexpr)
        if not ok then
            error(
                string.format(
                    "Invalid query: '%s'\n error: %s",
                    sexpr,
                    result_object
                )
            )
        end

        local out = {}
        for id, node, _ in result_object:iter_captures(scope, bufnr, 0, -1) do
            if filter(id, node, result_object) then
                table.insert(out, node)
            end
        end
        return out
    end
end

---@param sexpr string
---@return fun(scope: TSNode, bufnr: integer): string
local QueryNode = function(sexpr)
    -- The reason why this works is because __tostring method is already
    -- implemented on string
    return function(scope, bufnr)
        local occurrences = Query.find_occurrences(scope, sexpr, bufnr)
        local first = occurrences[1]

        if first then
            local res = vim.treesitter.get_node_text(
                first,
                vim.api.nvim_get_current_buf()
            )
            return res or ""
        end

        return ""
    end
end

---@param  ... fun(... :any): string
---@return fun(... :any): string
local function TakeFirstNode(...)
    ---@type (fun(... :any): string)[]
    local nodes = to_array(...)
    return function(...)
        local out = ""

        for _, v in ipairs(nodes) do
            local value = v(...)
            if value and #value > 0 then
                out = value
                break
            end
        end

        return out
    end
end

return {
    BaseFieldNode = BaseFieldNode,
    TakeFirstNode = TakeFirstNode,
    StringNode = StringNode,
    QueryNode = QueryNode,
    FieldNode = FieldNode,
    InlineNode = InlineNode,
    InlineFilteredNode = InlineFilteredNode,
}
