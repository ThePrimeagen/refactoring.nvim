local ts_utils = require("nvim-treesitter.ts_utils")

local BaseFieldNode = {}
BaseFieldNode.__index = BaseFieldNode

local FieldNode = function(...)
    local fieldnames = {}
    for idx = 1, select("#", ...) do
        local item = select(idx, ...)
        table.insert(fieldnames, item)
    end

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

                return ts_utils.get_node_text(curr, 0)[1] or fallback
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

return {
    BaseFieldNode = BaseFieldNode,
    StringNode = StringNode,
    FieldNode = FieldNode,
}
