local Query = require("refactoring.query")

local BaseFieldNode = {}
BaseFieldNode.__index = BaseFieldNode

local function to_array(...)
    local items = {}

    for idx = 1, select("#", ...) do
        local item = select(idx, ...)
        table.insert(items, item)
    end

    return items
end

local FieldNode = function(...)
    local fieldnames = to_array(...)

    return function(node, fallback)
        return setmetatable({
            fieldnames = fieldnames,
            node = node,
        }, {
            __index = BaseFieldNode,

            __tostring = function(self)
                if not self.node then
                    return fallback
                end

                local curr = self.node
                for idx = 1, #self.fieldnames do
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

local StringNode = function(text)
    return function()
        return setmetatable({}, {
            __tostring = function()
                return text
            end,
        })
    end
end

local InlineNode = function(sexpr)
    return function(scope, bufnr, filetype)
        local ok, result_object =
            pcall(vim.treesitter.query.parse, filetype, sexpr)
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

local function TakeFirstNode(...)
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
}
