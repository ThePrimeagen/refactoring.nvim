local Query = require("refactoring.query")

local api = vim.api
local ts = vim.treesitter

local M = {}

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

---@class refactor.FieldnameNode
---@field fieldnames string[]
---@field node TSNode

---@alias refactor.FieldNodeFunc fun(node: TSNode?, fallback: integer|string): refactor.FieldnameNode

---@param ... string
---@return refactor.FieldNodeFunc
function M.FieldNode(...)
    ---@type string[]
    local fieldnames = to_array(...)

    ---@param node TSNode?
    ---@param fallback string
    ---@return refactor.FieldnameNode
    return function(node, fallback)
        return setmetatable({
            fieldnames = fieldnames,
            node = node,
        }, {
            __index = BaseFieldNode,

            ---@param self refactor.FieldnameNode
            ---@return string
            __tostring = function(self)
                if not self.node then
                    return fallback
                end

                local curr = self.node
                for idx = 1, #self.fieldnames do
                    curr = curr:field(self.fieldnames[idx])[1]

                    if not curr then
                        return fallback
                    end
                end

                return ts.get_node_text(curr, 0) or fallback
            end,
        })
    end
end

---@param text string
---@return fun(): table
function M.StringNode(text)
    return function()
        return setmetatable({}, {
            __tostring = function()
                return text
            end,
        })
    end
end

---@alias refactor.InlineNodeFunc fun(scope: TSNode, bufnr: integer, filetype: string): TSNode[]

---@param sexpr string sexpr of a capture
---@return refactor.InlineNodeFunc
function M.InlineNode(sexpr)
    return function(scope, bufnr, filetype)
        local lang = ts.language.get_lang(filetype)
        local ok, query = pcall(ts.query.parse, lang, sexpr)
        if not ok then
            error(("Invalid query: '%s'\n error: %s"):format(sexpr, query))
        end

        local out = {}
        for _, node, _ in query:iter_captures(scope, bufnr) do
            table.insert(out, node)
        end
        return out
    end
end

---@alias refactor.NodeFilter fun(id: integer, node: TSNode, query: vim.treesitter.Query): boolean
---@alias refactor.InlineFilteredNodeFunc fun(scope: TSNode, bufnr: integer, filetype: string, filter: refactor.NodeFilter): TSNode[]

---@param sexpr string sexpr with multiple captures
---@return refactor.InlineFilteredNodeFunc
function M.InlineFilteredNode(sexpr)
    return function(scope, bufnr, filetype, filter)
        local lang = ts.language.get_lang(filetype)
        local ok, query = pcall(ts.query.parse, lang, sexpr)
        if not ok then
            error(("Invalid query: '%s'\n error: %s"):format(sexpr, query))
        end

        local out = {}
        for id, node, _ in query:iter_captures(scope, bufnr) do
            if filter(id, node, query) then
                table.insert(out, node)
            end
        end
        return out
    end
end

---@param sexpr string
---@return fun(scope: TSNode, bufnr: integer): string
function M.QueryNode(sexpr)
    -- The reason why this works is because __tostring method is already
    -- implemented on string
    return function(scope, bufnr)
        local occurrences = Query.find_occurrences(scope, sexpr, bufnr)
        local first = occurrences[1]

        if first then
            local res = ts.get_node_text(first, api.nvim_get_current_buf())
            return res or ""
        end

        return ""
    end
end

---@param  ... fun(... :any): string
---@return fun(... :any): string
function M.TakeFirstNode(...)
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

return M
