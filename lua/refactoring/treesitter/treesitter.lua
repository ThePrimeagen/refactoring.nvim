local parsers = require("nvim-treesitter.parsers")
local Point = require("refactoring.point")
local utils = require("refactoring.utils")
local Version = require("refactoring.version")
local Region = require("refactoring.region")

-- TODO: Update class comments
---@class RefactorTS
--- The following fields act similar to a cursor
---@field scope_names table: The 1-based row
---@field valid_class_nodes table: list of valie class nodes
---@field class_names table: list of inline nodes for class name
---@field class_type table: list of inline nodes for class type
---@field local_var_names table: list of inline nodes for local variable names
---@field local_var_values table: list of inline nodes for local variable values
---@field local_declarations table: list of inline nodes for local declarations
---@field bufnr number: the bufnr to which this belongs
---@field version RefactorVersion: supperted operation flags
---@field filetype string: the filetype
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
        valid_class_nodes = {},
        class_names = {},
        class_type = {},
        local_var_names = {},
        local_var_values = {},
        local_declarations = {},
        debug_paths = {},
        statements = {},
        indent_scopes = {},
        parameter_list = {},
        function_scopes = {},
        bufnr = bufnr,
        require_class_name = false,
        require_class_type = false,
        require_param_types = false,
        allow_indenting_task = false,
        version = Version:new(),
        filetype = config.filetype,
    }, config)

    return setmetatable(c, self)
end

function TreeSitter:allows_indenting_task()
    return self.allow_indenting_task
end

function TreeSitter:is_indent_scope(scope)
    if self.indent_scopes[scope:type()] == nil then
        return false
    end
    return true
end

function TreeSitter:loop_thru_nodes(scope, inline_nodes)
    local out = {}
    for _, statement in ipairs(inline_nodes) do
        local temp = statement(scope, self.bufnr, self.filetype)
        for _, node in ipairs(temp) do
            table.insert(out, node)
        end
    end
    return out
end

function TreeSitter:get_local_var_names(node)
    return self:loop_thru_nodes(node, self.local_var_names)
end

function TreeSitter:get_local_var_values(node)
    return self:loop_thru_nodes(node, self.local_var_values)
end

function TreeSitter:get_statements(scope)
    return self:loop_thru_nodes(scope, self.statements)
end

function TreeSitter:is_class_function(scope)
    local node = scope
    while node ~= nil do
        if self.valid_class_nodes[node:type()] ~= nil then
            return true
        end
        if node:parent() == nil then
            break
        end
        node = node:parent()
    end
    return false
end

function TreeSitter:get_references(scope)
    local query = vim.treesitter.get_query(self.filetype, "locals")
    local out = {}
    for id, node, _ in query:iter_captures(scope, self.bufnr, 0, -1) do
        local n_capture = query.captures[id]
        if n_capture == "reference" then
            table.insert(out, node)
        end
    end
    return out
end

function TreeSitter:get_class_name(scope)
    self.version:ensure_version(TreeSitter.version_flags.Classes)
    if self.require_class_name then
        local class_name_node = self:loop_thru_nodes(scope, self.class_names)[1]
        local region = Region:from_node(class_name_node)
        return region:get_text()[1]
    end
    return nil
end

function TreeSitter:get_class_type(scope)
    self.version:ensure_version(TreeSitter.version_flags.Classes)
    if self.require_class_type then
        local class_type_node = self:loop_thru_nodes(scope, self.class_type)[1]
        local region = Region:from_node(class_type_node)
        return region:get_text()[1]
    end
    return nil
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
    -- This statement can be uncommented to print all the parent nodes of the
    -- current node until there are no more. Useful in finding certain nodes
    -- like the global scope node, which doesn't show up in playground.
    -- print(node:type())
    until node == nil

    return node
end

function TreeSitter:get_local_parameter_types(scope)
    local parameter_types = {}
    local function_node = containing_node_by_type(scope, self.function_scopes)

    -- Get parameter list
    local parameter_list_nodes = self:loop_thru_nodes(
        function_node,
        self.parameter_list
    )

    -- Only if we find something, else empty
    if #parameter_list_nodes > 0 then
        local region = Region:from_node(parameter_list_nodes[1])
        local parameter_list = region:get_text()
        local parameter_split = utils.split_string(parameter_list[1], " ")
        parameter_types[parameter_split[1]] = parameter_split[2]
    end
    return parameter_types
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
function TreeSitter:get_local_declarations(scope)
    self.version:ensure_version(TreeSitter.version_flags.Scopes)
    local all_defs = self:loop_thru_nodes(scope, self.local_declarations)
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
    return utils.region_intersect(self:get_local_declarations(scope), region)
end

function TreeSitter:local_declarations_under_cursor()
    self.version:ensure_version(TreeSitter.version_flags.Locals)
    local point = Point:from_cursor()
    local scope = self:get_scope(point:to_ts_node(self:get_root()))
    return vim.tbl_filter(function(node)
        return Region:from_node(node, 0):contains_point(point)
    end, self:get_local_declarations(scope))[1]
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
