local ts_utils = require("nvim-treesitter.ts_utils")

local BaseFieldNode = {}
BaseFieldNode.__index = BaseFieldNode

local FieldNode = function(fieldname, idx)
    idx = idx or 1
    return function(node)
        return setmetatable({
            fieldname = fieldname,
            node = node,
        }, {
            __index = BaseFieldNode,

            __tostring = function(self)
                local name_node = self.node:field(self.fieldname)[idx]
                return ts_utils.get_node_text(name_node, 0)[1]
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
