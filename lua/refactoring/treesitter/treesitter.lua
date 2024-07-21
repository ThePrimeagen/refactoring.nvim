local Point = require("refactoring.point")
local utils = require("refactoring.utils")
local Region = require("refactoring.region")
local ts_locals = require("refactoring.ts-locals")

---@class TreeSitterLanguageConfig
---@field bufnr integer bufnr to which this belongs
---@field filetype string filetype
---@field scope_names table<string, string> nodes that are scopes in current buffer
---@field block_scope table<string, true> scopes that are blocks in current buffer
---@field variable_scope table<string, true> scopes that contain variables in current buffer
---@field local_var_names InlineNodeFunc[] nodes for local variable names
---@field function_args InlineNodeFunc[] nodes to find args for a function
---@field local_var_values InlineNodeFunc[] nodes for local variable values
---@field local_declarations InlineNodeFunc[] nodes for local declarations
---@field indent_scopes table<string, true> nodes where code has addition indent inside
---@field debug_paths table<string, FieldNodeFunc> map of node types to FieldNodeFunc
---@field statements InlineNodeFunc[] nodes of statements in current scope
---@field function_body InlineNodeFunc[] nodes to find body for a function
---@field require_param_types? boolean flag to require parameter types for codegen
---@field valid_class_nodes? table<string, 0|1|true> nodes that mean scope is a class function
---@field class_names? InlineNodeFunc[] nodes to get class names
---@field class_type? InlineNodeFunc[] nodes to get types for classes
---@field ident_with_type? InlineFilteredNodeFunc[] nodes to get all identifiers and types for a scope
---@field require_class_name? boolean flag to require class name for codegen
---@field require_class_type? boolean flag to require class type for codegen
---@field require_special_var_format? boolean: flag to require special variable format for codegen
---@field should_check_parent_node? fun(parent_type: string): boolean function to check if it's necesary to check the parent node
---@field should_check_parent_node_print_var? fun(parent_type: string): boolean function to check if it's necesary to check the parent node for print_var
---@field reference_filter? fun(node: TSNode): boolean
---@field include_end_of_line? boolean flag to indicate if end of line should be included in a region
---@field return_values InlineNodeFunc[] nodes that are return values
---@field function_references InlineNodeFunc[] nodes that are references of function
---@field caller_args InlineNodeFunc[] nodes that are arguments passed to a function when it's called
---@field return_statement InlineNodeFunc[] nodes that are return statements
---@field is_return_statement fun(statement: string): boolean function to check if a statement is a return statement

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
        local_var_names = {},
        local_var_values = {},
        local_declarations = {},
        debug_paths = {},
        statements = {},
        indent_scopes = {},
        ident_with_type = {},
        function_args = {},
        function_body = {},
        return_values = {},
        function_references = {},
        caller_args = {},
        return_statement = {},
        bufnr = bufnr,
        require_class_name = false,
        require_class_type = false,
        require_param_types = false,
        require_special_variable_format = false,
        require_special_var_format = false,
        should_check_parent_node = function(_parent_type)
            return false
        end,
        should_check_parent_node_print_var = function(_parent_type)
            return false
        end,
        reference_filter = function(_node)
            return true
        end,
        include_end_of_line = false,
        filetype = config.filetype,
    }
    local c = vim.tbl_extend("force", default_config, config)

    return setmetatable(c, self)
end

---@param setting table
---@return boolean
local function setting_present(setting)
    ---@diagnostic disable-next-line: no-unknown
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
---@param inline_nodes InlineFilteredNodeFunc[]
---@param filter NodeFilter
---@return TSNode[]
function TreeSitter:loop_thru_filtered_nodes(scope, inline_nodes, filter)
    local out = {}
    for _, statement in ipairs(inline_nodes) do
        local temp = statement(scope, self.bufnr, self.filetype, filter)
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

    nodes = vim.iter(nodes)
        :filter(function(node)
            return utils.region_complement(node, region)
        end)
        :filter(
            --- @param node TSNode
            ---@return boolean
            function(node)
                return Region:from_node(node):above(region)
            end
        )
        :totable()
    return nodes
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
---@return TSNode[]
function TreeSitter:get_return_values(scope)
    self:validate_setting("return_values")
    return self:loop_thru_nodes(scope, self.return_values)
end

---@param scope TSNode
---@return TSNode[]
function TreeSitter:get_function_args(scope)
    self:validate_setting("function_args")
    return self:loop_thru_nodes(scope, self.function_args)
end

---@param scope TSNode
---@return TSNode[]
function TreeSitter:get_return_statements(scope)
    self:validate_setting("return_statement")
    return self:loop_thru_nodes(scope, self.return_statement)
end

---@param scope TSNode
---@return boolean
function TreeSitter:is_class_function(scope)
    local node = scope ---@type TSNode?
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
    local lang = vim.treesitter.language.get_lang(ft)

    if lang == nil then
        error(
            string.format(
                "The filetype %s has no treesitter lang asociated with it",
                ft
            )
        )
    end

    local query = vim.treesitter.query.get(lang, "locals")

    if query == nil then
        error(string.format("The lang %s has no query `locals`", lang))
    end

    ---@type TSNode[]
    local out = {}
    for id, node, _ in query:iter_captures(scope, self.bufnr, 0, -1) do
        local n_capture = query.captures[id]
        if n_capture == ts_locals.local_reference then
            table.insert(out, node)
        end
    end
    return out
end

---@param scope TSNode
---@param region RefactorRegion
---@return TSNode[]
function TreeSitter:get_region_refs(scope, region)
    local nodes = vim.iter(self:get_references(scope))
        :filter(function(node)
            return utils.region_intersect(node, region, region.bufnr)
        end)
        :totable()

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

---@param node? TSNode
---@param container_map table<string, any>
---@return TSNode|nil
local function containing_node_by_type(node, container_map)
    if not node then
        return nil
    end

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
---@return table<string, string>
function TreeSitter:get_local_types(scope)
    --- @type table<string, string>
    local all_types = {}

    self:validate_setting("ident_with_type")
    local idents = self:loop_thru_filtered_nodes(
        scope,
        self.ident_with_type,
        function(id, _node, query)
            local name = query.captures[id]
            return name == "ident"
        end
    )
    local types = self:loop_thru_filtered_nodes(
        scope,
        self.ident_with_type,
        function(id, _node, query)
            local name = query.captures[id]
            return name == "type"
        end
    )

    if #types > 0 then
        for i = 1, #types do
            local type = vim.treesitter.get_node_text(types[i], self.bufnr)
            local ident = vim.treesitter.get_node_text(idents[i], self.bufnr)
            all_types[ident] = type
        end
    end

    return all_types
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
        ---@diagnostic disable-next-line: cast-local-type
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

    local curr = node ---@type TSNode?
    repeat
        curr = containing_node_by_type(curr, self.debug_paths)

        if curr then
            table.insert(path, self.debug_paths[curr:type()](curr, self.bufnr))
            curr = curr:parent()
        end
    until curr == nil

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
    return vim.iter(self:get_local_declarations(scope))
        :filter(function(node)
            return utils.region_intersect(node, region)
        end)
        :totable()
end

---@return TSNode
function TreeSitter:local_declarations_under_cursor()
    self:validate_setting("local_declarations")
    local point = Point:from_cursor()
    local scope = self:get_scope(point:to_ts_node(self:get_root()))

    if scope == nil then
        error("Failed to get scope in local_declarations_under_cursor")
    end

    return vim.iter(self:get_local_declarations(scope))
        :filter(
            --- @param node TSNode
            --- @return boolean
            function(node)
                return Region:from_node(node, 0):contains_point(point)
            end
        )
        :next()
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
    local lang = vim.treesitter.language.get_lang(self.filetype)
    local parser = vim.treesitter.get_parser(self.bufnr, lang)
    return parser:parse()[1]:root()
end

return TreeSitter
