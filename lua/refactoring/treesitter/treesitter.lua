local parsers = require("nvim-treesitter.parsers")
local Query = require("refactoring.query")
local Point = require("refactoring.point")
local utils = require("refactoring.utils")
local Version = require("refactoring.treesitter.version")

---@class TreeSitter
--- The following fields act similar to a cursor
---@field scope_names table: The 1-based row
---@field bufnr number: the bufnr to which this belongs
---@field filetype string: the filetype
---@field version number: supperted operation flags
---@field query Query: the refactoring query
local TreeSitter = {}
TreeSitter.__index = TreeSitter

---@return TreeSitter
function TreeSitter:new(config, bufnr)
    local c = vim.tbl_extend("force", {
        scope_names = {},
        bufnr = bufnr,
        version = 0,
    }, config)

    c.query = Query.from_query_name(
        config.bufnr,
        config.filetype,
        "refactoring"
    )

    return setmetatable(c, self)
end

local function containing_node_by_type(node, container_map)
    -- assume that its a number / string.
    if type(container_map) ~= "table" then
        container_map = { container_map = true }
    end

    repeat
        if container_map[node:type()] ~= nil then
            break
        end
        node = node:parent()
    until node == nil

    return node
end

-- Will walk through the top level statements of the
function TreeSitter:local_declarations(scope)
    Version.ensure_version(self.version, Version.Scopes)
    local all_defs = self.query:pluck_by_capture(
        scope,
        Query.query_type.Declarator
    )
    local defs = {}

    -- this ensures they are all on the same level
    local scope_id = scope:id()
    for _, def in ipairs(all_defs) do
        if self:get_scope(def):id() == scope_id then
            table.insert(defs, def)
        end
    end
    return defs
end

function TreeSitter:local_declarations_in_region(scope, region)
    Version.ensure_version(self.version, Version.Locals)
    return utils.region_intersect(self:local_declarations(scope), region)
end

function TreeSitter:local_declarations_under_cursor()
    Version.ensure_version(self.version, Version.Locals)
    local point = Point:from_cursor()
    local scope = self:get_scope(point:to_ts_node(self:get_root()))
    return vim.tbl_filter(function(node)
        return point:within_node(node)
    end, self:local_declarations(
        scope
    ))[1]
end

function TreeSitter:get_scope(node)
    Version.ensure_version(self.version, Version.Scopes)
    return containing_node_by_type(node, self.scope_names)
end

function TreeSitter:get_parent_scope(node)
    Version.ensure_version(self.version, Version.Scopes)
    return containing_node_by_type(node:parent(), self.scope_names)
end

function TreeSitter:get_root()
    local parser = parsers.get_parser(self.bufnr, self.filetype)
    return parser:parse()[1]:root()
end

return TreeSitter
