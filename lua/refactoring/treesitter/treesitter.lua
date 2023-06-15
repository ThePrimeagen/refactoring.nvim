local parsers = require("nvim-treesitter.parsers")
local Point = require("refactoring.point")
local utils = require("refactoring.utils")
local Region = require("refactoring.region")

---@class TreeSitterLanguageConfig
---@field bufnr integer: the bufnr to which this belongs
---@field filetype string: the filetype
---@field scope_names table<string, string>: nodes that are scopes in current buffer
---@field block_scope table<string, true>: scopes that are blocks in current buffer
---@field variable_scope table<string, true>: scopes that contain variables in current buffer
---@field local_var_names InlineNodeFunc[]: list of inline nodes for local variable names
---@field function_args InlineNodeFunc[]: nodes to find args for a function
---@field local_var_values InlineNodeFunc[]: list of inline nodes for local variable values
---@field local_declarations InlineNodeFunc[]: list of inline nodes for local declarations
---@field indent_scopes table<string, true>: nodes where code has addition indent inside
---@field debug_paths table<string, FieldNodeFunc>: nodes to know path for debug strings
---@field statements InlineNodeFunc[]: statements in current scope
---@field function_body InlineNodeFunc[]: nodes to find body for a function
---@field require_param_types boolean: flag to require parameter types for codegen
---@field valid_class_nodes table<string, 0|1|true>: nodes that mean scope is a class function
---@field class_names InlineNodeFunc[]: nodes to get class names
---@field class_type InlineNodeFunc[]: nodes to get types for classes
---@field class_vars InlineNodeFunc[]: nodes to get class variable assignments in a scope
---@field parameter_list InlineNodeFunc[]: nodes to get list of parameters for a function
---@field function_scopes table<string, string|true>: nodes to find a function declaration
---@field require_class_name boolean: flag to require class name for codegen
---@field require_class_type boolean: flag to require class type for codegen
---@field argument_type_index 1|2: 1-indexed location of type in function args (int foo= 1, foo int= 2)
---@field require_special_var_format boolean: flag to require special variable format for codegen
---@field should_check_parent_node fun(parent_type: string): boolean is checking the parent node necesary for context?

--- The following fields act similar to a cursor
---@class TreeSitter: TreeSitterLanguageConfig
local TreeSitter = {}
TreeSitter.__index = TreeSitter

---@param config TreeSitterLanguageConfig
---@param bufnr integer
---@return TreeSitter
function TreeSitter:new(config, bufnr)
    ---@class TreeSitterLanguageConfig
    local default_config = {
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
        require_special_variable_format = false,
        argument_type_index = 2,
        filetype = config.filetype,
    }
    local c = vim.tbl_extend("force", default_config, config)

    return setmetatable(c, self)
end

---@param setting table
---@return boolean
local function setting_present(setting)
    for _ in pairs(setting) do
        return true
    end
    return false
end

---@param setting string
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

---@param arg string
---@return string
function TreeSitter.get_arg_type_key(arg)
    return arg
end

---@return boolean: whether to allow indenting operations
function TreeSitter:allows_indenting_task()
    return setting_present(self.indent_scopes)
end

---@param scope TSNode
---@return boolean
function TreeSitter:is_indent_scope(scope)
    if self.indent_scopes[scope:type()] == nil then
        return false
    end
    return true
end

---@param scope TSNode
---@param inline_nodes InlineNodeFunc[]
---@return TSNode[]
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

---@param scope TSNode
---@param region RefactorRegion
---@return TSNode[]
function TreeSitter:get_local_defs(scope, region)
    self:validate_setting("function_args")
    local nodes = self:loop_thru_nodes(scope, self.function_args)
    local local_var_names = self:get_local_var_names(scope)

    vim.list_extend(nodes, local_var_names)

    nodes = utils.region_complement(nodes, region)
    return nodes
end

---@param scope TSNode
---@param region RefactorRegion
---@return TSNode[]
function TreeSitter:get_class_vars(scope, region)
    -- TODO: add validate setting
    local class_var_nodes = self:loop_thru_nodes(scope, self.class_vars)
    return utils.region_complement(class_var_nodes, region)
end

---@param node TSNode
---@return TSNode[]
function TreeSitter:get_local_var_names(node)
    self:validate_setting("local_var_names")
    return self:loop_thru_nodes(node, self.local_var_names)
end

---@param node TSNode
---@return TSNode[]
function TreeSitter:get_local_var_values(node)
    self:validate_setting("local_var_values")
    return self:loop_thru_nodes(node, self.local_var_values)
end

---@param scope TSNode
---@return TSNode[]
function TreeSitter:get_statements(scope)
    self:validate_setting("statements")
    return self:loop_thru_nodes(scope, self.statements)
end

---@param scope TSNode
---@return TSNode[]
function TreeSitter:get_function_body(scope)
    self:validate_setting("function_body")
    return self:loop_thru_nodes(scope, self.function_body)
end

---@param scope TSNode
---@return boolean
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

---@param scope TSNode
---@return TSNode[]
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

---@param scope TSNode
---@param region RefactorRegion
---@return TSNode[]
function TreeSitter:get_region_refs(scope, region)
    local nodes = self:get_references(scope)

    nodes = utils.region_intersect(nodes, region, region.bufnr)
    return nodes
end

---@return boolean
function TreeSitter:class_support()
    return setting_present(self.valid_class_nodes)
end

---@param scope TSNode
---@return string|nil
function TreeSitter:get_class_name(scope)
    if self.require_class_name then
        self:validate_setting("class_names")
        local class_name_node = self:loop_thru_nodes(scope, self.class_names)[1]
        local region = Region:from_node(class_name_node)
        return region:get_text()[1]
    end
    return nil
end

---@param scope TSNode
---@return string|nil
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
---@param container_map table<string, any>
---@return TSNode|nil
local function containing_node_by_type(node, container_map)
    if not node then
        return nil
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

---@param scope TSNode
---@param type_index integer
---@return table<string, string>
function TreeSitter:get_local_parameter_types(scope, type_index)
    local parameter_types = {}
    self:validate_setting("function_scopes")
    local function_node = containing_node_by_type(scope, self.function_scopes)

    if function_node == nil then
        error(
            "Failed to get function_node in get_local_parameter_types, check `function_scopes` queries"
        )
    end

    -- Get parameter list
    self:validate_setting("parameter_list")
    local parameter_list_nodes =
        self:loop_thru_nodes(function_node, self.parameter_list)

    -- Only if we find something, else empty
    if #parameter_list_nodes > 0 then
        for _, node in pairs(parameter_list_nodes) do
            local region = Region:from_node(node, self.bufnr)
            local parameter_list = region:get_text()
            local parameter_split = utils.split_string(parameter_list[1], " ")

            local arg_index = type_index == 2 and 1 or 2
            parameter_types[parameter_split[arg_index]] =
                parameter_split[type_index]
        end
    end

    return parameter_types
end

---@param node TSNode
---@return TSNode|nil
function TreeSitter:indent_scope(node)
    self:validate_setting("indent_scopes")
    return containing_node_by_type(node:parent(), self.indent_scopes)
end

---@param ancestor TSNode
---@param child TSNode
---@return integer
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

---@param node TSNode
---@return FieldnameNode[]
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
---@param scope TSNode
---@return TSNode[]
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

---@param scope TSNode
---@param region  RefactorRegion
---@return TSNode[]
function TreeSitter:local_declarations_in_region(scope, region)
    return utils.region_intersect(self:get_local_declarations(scope), region)
end

---@return TSNode
function TreeSitter:local_declarations_under_cursor()
    self:validate_setting("local_declarations")
    local point = Point:from_cursor()
    local scope = self:get_scope(point:to_ts_node(self:get_root()))
    return vim.tbl_filter(function(node)
        return Region:from_node(node, 0):contains_point(point)
    end, self:get_local_declarations(scope))[1]
end

---@param node TSNode
---@param container_list table<string, any>
---@return TSNode|nil
function TreeSitter.get_container(node, container_list)
    return containing_node_by_type(node, container_list)
end

---@param node TSNode
---@return TSNode|nil
function TreeSitter:get_scope(node)
    self:validate_setting("scope_names")
    return containing_node_by_type(node, self.scope_names)
end

---@param node TSNode
---@return TSNode|nil
function TreeSitter:get_parent_scope(node)
    self:validate_setting("scope_names")
    return containing_node_by_type(node:parent(), self.scope_names)
end

---@return TSNode
function TreeSitter:get_root()
    -- TODO (TheLeoP): typescriptreact parser name is tsx
    local ft = self.filetype == "typescriptreact" and "tsx" or self.filetype
    local parser = parsers.get_parser(self.bufnr, ft)
    return parser:parse()[1]:root()
end

return TreeSitter
