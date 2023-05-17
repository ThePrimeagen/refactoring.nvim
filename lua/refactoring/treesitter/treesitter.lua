local parsers = require("nvim-treesitter.parsers")
local Point = require("refactoring.point")
local utils = require("refactoring.utils")
local Region = require("refactoring.region")

---@class TreeSitter
--- The following fields act similar to a cursor
---@field scope_names table: nodes that are scopes in current buffer
---@field block_scope table: scopes that are blocks in current buffer
---@field valid_class_nodes table: nodes that mean scope is a class function
---@field class_names table: nodes to get class names
---@field class_type table: nodes to get types for classes
---@field class_vars table: nodes to get class variable assignments in a scope
---@field local_var_names table: list of inline nodes for local variable names
---@field local_var_values table: list of inline nodes for local variable values
---@field local_declarations table: list of inline nodes for local declarations
---@field debug_paths table: nodes to know path for debug strings
---@field statements table: statements in current scope
---@field indent_scopes table: nodes where code has addition indent inside
---@field parameter_list table: nodes to get list of parameters for a function
---@field function_scopes table: nodes to find a function declaration
---@field function_args table: nodes to find args for a function
---@field function_body table: nodes to find body for a function
---@field bufnr number: the bufnr to which this belongs
---@field require_class_name boolean: flag to require class name for codegen
---@field require_class_type boolean: flag to require class type for codegen
---@field require_param_types boolean: flag to require parameter types for codegen
---@field filetype string: the filetype
---@field query RefactorQuery: the refactoring query
local TreeSitter = {}
TreeSitter.__index = TreeSitter

---@return TreeSitter
function TreeSitter:new(config, bufnr)
    local c = vim.tbl_extend("force", {
        scope_names = {},
        valid_class_nodes = {},
        class_names = {},
        class_type = {},
        class_vars = {},
        local_var_names = {},
        local_var_values = {},
        local_declarations = {},
        debug_paths = {},
        statements = {},
        indent_scopes = {},
        parameter_list = {},
        function_scopes = {},
        function_args = {},
        function_body = {},
        bufnr = bufnr,
        require_class_name = false,
        require_class_type = false,
        require_param_types = false,
        filetype = config.filetype,
    }, config)

    return setmetatable(c, self)
end

local function setting_present(setting)
    for _ in pairs(setting) do
        return true
    end
    return false
end

function TreeSitter:validate_setting(setting)
    if self[setting] == nil then
        error(
            string.format(
                "%s setting does not exist on treesitter class",
                setting
            )
        )
    end

    if not setting_present(self[setting]) then
        error(
            string.format(
                "%s setting is empty in treesitter for this language",
                setting
            )
        )
    end
end

function TreeSitter.get_arg_type_key(arg)
    return arg
end

---@return boolean: whether to allow indenting operations
function TreeSitter:allows_indenting_task()
    return setting_present(self.indent_scopes)
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

function TreeSitter:get_local_defs(scope, region)
    self:validate_setting("function_args")
    local nodes = self:loop_thru_nodes(scope, self.function_args)
    local local_var_names = self:get_local_var_names(scope)
    local i = #nodes + 1
    for _, v in ipairs(local_var_names) do
        nodes[i] = v
        i = i + 1
    end
    nodes = utils.region_complement(nodes, region)
    return nodes
end

function TreeSitter:get_class_vars(scope, region)
    -- TODO: add validate setting
    local class_var_nodes = self:loop_thru_nodes(scope, self.class_vars)
    return utils.region_complement(class_var_nodes, region)
end

function TreeSitter:get_local_var_names(node)
    self:validate_setting("local_var_names")
    return self:loop_thru_nodes(node, self.local_var_names)
end

function TreeSitter:get_local_var_values(node)
    self:validate_setting("local_var_values")
    return self:loop_thru_nodes(node, self.local_var_values)
end

function TreeSitter:get_statements(scope)
    self:validate_setting("statements")
    return self:loop_thru_nodes(scope, self.statements)
end

function TreeSitter:get_function_body(scope)
    self:validate_setting("function_body")
    return self:loop_thru_nodes(scope, self.function_body)
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
    local ft = self.filetype
    -- TODO (TheLeoP): typescriptreact parser name is tsx
    if ft == "typescriptreact" then
        ft = "tsx"
    end
    local query = vim.treesitter.query.get(ft, "locals")
    local out = {}
    for id, node, _ in query:iter_captures(scope, self.bufnr, 0, -1) do
        local n_capture = query.captures[id]
        if n_capture == "reference" then
            table.insert(out, node)
        end
    end
    return out
end

function TreeSitter:get_region_refs(scope, region)
    local nodes = self:get_references(scope)
    nodes = utils.region_intersect(nodes, region)
    return nodes
end

function TreeSitter:class_support()
    return setting_present(self.valid_class_nodes)
end

function TreeSitter:get_class_name(scope)
    if self.require_class_name then
        self:validate_setting("class_names")
        local class_name_node = self:loop_thru_nodes(scope, self.class_names)[1]
        local region = Region:from_node(class_name_node)
        return region:get_text()[1]
    end
    return nil
end

function TreeSitter:get_class_type(scope)
    if self.require_class_type then
        self:validate_setting("class_type")
        local class_type_node = self:loop_thru_nodes(scope, self.class_type)[1]
        local region = Region:from_node(class_type_node)
        return region:get_text()[1]
    end
    return nil
end

---@param node TSNode
---@param container_map table|number|string
---@return TSNode|nil
local function containing_node_by_type(node, container_map)
    if not node then
        return nil
    end

    -- assume that its a number / string.
    if type(container_map) ~= "table" then
        container_map = { container_map = true }
    end

    -- TODO (TheLeoP): fix: if multiple containing nodes have the same type, this returns the first match, not necesarily the containing node (example: golang "block")
    repeat
        if container_map[node:type()] ~= nil then
            break
        end
        node = node:parent()
    -- This statement can be uncommented to print all the parent nodes of the
    -- current node until there are no more. Useful in finding certain nodes
    -- like the global scope node, which doesn't show up in playground.
    -- vim.print({ type = node:type(), container_map })
    until node == nil

    return node
end

-- TODO: Can we validate settings here without breaking things?
function TreeSitter:get_local_parameter_types(scope)
    local parameter_types = {}
    local function_node = containing_node_by_type(scope, self.function_scopes)

    -- TODO: Uncomment this error once validate settings in this func
    -- if function_node == nil then
    -- error(
    -- "Failed to get function_node in get_local_parameter_types, check `function_scopes` queries"
    -- )
    -- end

    -- Get parameter list
    local parameter_list_nodes =
        self:loop_thru_nodes(function_node, self.parameter_list)

    -- Only if we find something, else empty
    if #parameter_list_nodes > 0 then
        for _, node in pairs(parameter_list_nodes) do
            local region = Region:from_node(node, self.bufnr)
            local parameter_list = region:get_text()
            local parameter_split = utils.split_string(parameter_list[1], " ")
            parameter_types[parameter_split[1]] = parameter_split[2]
        end
    end

    return parameter_types
end

function TreeSitter:indent_scope(node)
    self:validate_setting("indent_scopes")
    return containing_node_by_type(node:parent(), self.indent_scopes)
end

function TreeSitter:indent_scope_difference(ancestor, child)
    self:validate_setting("indent_scopes")

    if ancestor == child then
        return 0
    end

    local indent_count = 0
    local ancestor_container =
        containing_node_by_type(ancestor, self.indent_scopes)
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
    self:validate_setting("debug_paths")
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
    self:validate_setting("local_declarations")
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
    return utils.region_intersect(self:get_local_declarations(scope), region)
end

function TreeSitter:local_declarations_under_cursor()
    self:validate_setting("local_declarations")
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
    self:validate_setting("scope_names")
    return containing_node_by_type(node, self.scope_names)
end

function TreeSitter:get_parent_scope(node)
    self:validate_setting("scope_names")
    return containing_node_by_type(node:parent(), self.scope_names)
end

function TreeSitter:get_root()
    local ft = self.filetype == "typescriptreact" and "tsx" or self.filetype
    local parser = parsers.get_parser(self.bufnr, ft)
    return parser:parse()[1]:root()
end

return TreeSitter
