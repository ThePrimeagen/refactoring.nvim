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
    Indents = 0x8,
}

---@return TreeSitter
function TreeSitter:new(config, bufnr)
    local c = vim.tbl_extend("force", {
        scope_names = {},
        class_names = {},
        debug_paths = {},
        indent_scopes = {},
        bufnr = bufnr,
        require_class_name = false,
        require_class_type = false,
        version = Version:new(),
    }, config)

    c.query = Query.from_query_name(
        config.bufnr,
        config.filetype,
        "refactoring"
    )

    return setmetatable(c, self)
end

-- TODO: Should be moved to node
function TreeSitter:local_var_names(node)
    return self.query:pluck_by_capture(node, Query.query_type.LocalVarName)[1]
end

-- TODO: Should be moved to node
function TreeSitter:local_var_values(node)
    return self.query:pluck_by_capture(node, Query.query_type.LocalVarValue)[1]
end

-- TODO: Create inline node for TS stuff.
function TreeSitter:statements(scope)
    return self.query:pluck_by_capture(scope, Query.query_type.Statement)
end

function TreeSitter:is_class_function(scope)
    local node = scope
    while node ~= nil do
        if self.class_names[node:type()] ~= nil then
            return true
        end
        if node:parent() == nil then
            break
        end
        node = node:parent()
    end
    return false
end

function TreeSitter:class_name(scope)
    self.version:ensure_version(TreeSitter.version_flags.Classes)
    if self.require_class_name then
        -- TODO: change to Node
        local class_name_node = self.query:pluck_by_capture(
            scope,
            Query.query_type.ClassName
        )[1]
        local region = Region:from_node(class_name_node)
        return region:get_text()[1]
    else
        return nil
    end
end

function TreeSitter:class_type(scope)
    self.version:ensure_version(TreeSitter.version_flags.Classes)
    if self.require_class_type then
        -- TODO: change to Node
        local class_type_node = self.query:pluck_by_capture(
            scope,
            Query.query_type.ClassType
        )[1]
        local region = Region:from_node(class_type_node)
        return region:get_text()[1]
    else
        return nil
    end
end

local function containing_node_by_type(node, container_map)
    if not node then
        return nil
    end

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

function TreeSitter:indent_scope(node)
    return containing_node_by_type(node:parent(), self.indent_scopes)
end

function TreeSitter:indent_scope_difference(ancestor, child)
    self.version:ensure_version(TreeSitter.version_flags.Indents)

    if ancestor == child then
        return 0
    end

    local indent_count = 0
    local ancestor_container = containing_node_by_type(
        ancestor,
        self.indent_scopes
    )
    if ancestor_container ~= ancestor then
        error("Ancestor is not a indent scope container.")
    end

    local curr = child
    repeat
        curr = containing_node_by_type(curr:parent(), self.indent_scopes)
        indent_count = indent_count + 1
    until curr == ancestor or curr == nil

    if curr == nil then
        error("child and ancestor are not in the same tree")
    end

    return indent_count
end

function TreeSitter:get_debug_path(node)
    local path = {}

    repeat
        node = containing_node_by_type(node, self.debug_paths)

        if node then
            table.insert(path, self.debug_paths[node:type()](node, self.bufnr))
            node = node:parent()
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
        return Region:from_node(node, 0):contains_point(point)
    end, self:local_declarations(scope))[1]
end

function TreeSitter.get_container(node, container_list)
    return containing_node_by_type(node, container_list)
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

return TreeSitter
