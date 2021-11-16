local parsers = require("nvim-treesitter.parsers")
local Query = require("refactoring.query")
local Point = require("refactoring.point")
local utils = require("refactoring.utils")
local Version = require("refactoring.version")
local Region = require("refactoring.region")

---@class RefactorTS
--- The following fields act similar to a cursor
---@field scope_names table: The 1-based row
---@field class_names Array: names of nodes that are classes
---@field bufnr number: the bufnr to which this belongs
---@field filetype string: the filetype
---@field version RefactorVersion: supperted operation flags
---@field query RefactorQuery: the refactoring query
---@field debug_paths table: Debug Paths
local TreeSitter = {}
TreeSitter.__index = TreeSitter
TreeSitter.version_flags = {
    Scopes = 0x1,
    Locals = 0x2,
    Classes = 0x4,
}

---@return TreeSitter
function TreeSitter:new(config, bufnr)
    local c = vim.tbl_extend("force", {
        scope_names = {},
        class_names = {},
        debug_paths = {},
        bufnr = bufnr,
        version = Version:new(),
    }, config)

    c.query = Query.from_query_name(
        config.bufnr,
        config.filetype,
        "refactoring"
    )

    return setmetatable(c, self)
end

function TreeSitter:is_class_function(scope)
    if self.class_names[scope:type()] ~= nil then
        return true
    end
    return false
end

function TreeSitter:class_name(scope)
    self.version:ensure_version(TreeSitter.version_flags.Classes)
    local class_name_node = self.query:pluck_by_capture(
        scope,
        Query.query_type.ClassName
    )[1]
    local region = Region:from_node(class_name_node)
    return region:get_text()[1]
end

function TreeSitter:class_type(scope)
    self.version:ensure_version(TreeSitter.version_flags.Classes)
    local class_type_node = self.query:pluck_by_capture(
        scope,
        Query.query_type.ClassType
    )[1]
    local region = Region:from_node(class_type_node)
    return region:get_text()[1]
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

function TreeSitter:get_debug_path(node)
    local path = {}

    repeat
        node = containing_node_by_type(node:parent(), self.debug_paths)

        if node then
            table.insert(path, self.debug_paths[node:type()](node))
        end
    until node == nil

    return path
end

-- Will walk through the top level statements of the
function TreeSitter:local_declarations(scope)
    self.version:ensure_version(TreeSitter.version_flags.Scopes)
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
    self.version:ensure_version(TreeSitter.version_flags.Locals)
    return utils.region_intersect(self:local_declarations(scope), region)
end

function TreeSitter:local_declarations_under_cursor()
    self.version:ensure_version(TreeSitter.version_flags.Locals)
    local point = Point:from_cursor()
    local scope = self:get_scope(point:to_ts_node(self:get_root()))
    return vim.tbl_filter(function(node)
        return point:within_node(node)
    end, self:local_declarations(scope))[1]
end

function TreeSitter:get_scope(node)
    self.version:ensure_version(TreeSitter.version_flags.Scopes)
    return containing_node_by_type(node, self.scope_names)
end

function TreeSitter:get_parent_scope(node)
    self.version:ensure_version(TreeSitter.version_flags.Scopes)
    return containing_node_by_type(node:parent(), self.scope_names)
end

function TreeSitter:get_root()
    local parser = parsers.get_parser(self.bufnr, self.filetype)
    return parser:parse()[1]:root()
end

function TreeSitter:to_string(node)
    print("node type:", node:type())
    error("to_string not supported for ", self.filetype)
end

return TreeSitter
