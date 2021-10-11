local parsers = require("nvim-treesitter.parsers")

---@class TreeSitter
--- The following fields act similar to a cursor
---@field scope_names table: The 1-based row
---@field bufnr number: the bufnr to which this belongs
---@field ft string: the filetype
local TreeSitter = {}
TreeSitter.__index = TreeSitter

---@return TreeSitter
function TreeSitter:new(config)
    return setmetatable(
        vim.tbl_extend("force", {
            scope_names = {},
            bufnr = 0,
        }, config),
        self
    )
end

function TreeSitter:get_scope_name(node)
    return self.scope_names[node:type()]
end

function TreeSitter:get_scope(node)
    repeat
        if self.scope_names[node:type()] ~= nil then
            break
        end
        node = node:parent()
    until node == nil

    return node
end

function TreeSitter:get_parent_scope(node)
    return self:get_scope(node:parent())
end

function TreeSitter:get_root()
    local parser = parsers.get_parser(self.bufnr, self.ft)
    return parser:parse()[1]:root()
end

return TreeSitter
