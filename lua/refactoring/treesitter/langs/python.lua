local TreeSitter = require("refactoring.treesitter.treesitter")
local Nodes = require("refactoring.treesitter.nodes")
local FieldNode = Nodes.FieldNode
local InlineNode = Nodes.InlineNode
local InlineFilteredNode = Nodes.InlineFilteredNode

---@class TreeSitterInstance
local Python = {}

function Python.new(bufnr, ft)
    ---@type TreeSitterLanguageConfig
    local config = {
        filetype = ft,
        bufnr = bufnr,
        require_param_types = true,
        scope_names = {
            function_definition = "function",
            module = "program",
        },
        block_scope = {
            block = true,
            function_definition = true,
            module = true,
        },
        variable_scope = {
            assignment = true,
        },
        local_var_names = {
            InlineNode(
                '(assignment left: (identifier) @capture (#not-eq? @capture "self"))'
            ),
            InlineNode(
                '(assignment left: (pattern_list (identifier) @capture) (#not-eq? @capture "self"))'
            ),
            InlineNode(
                '(assignment left: (tuple_pattern (identifier) @capture) (#not-eq? @capture "self"))'
            ),
            InlineNode(
                '(assignment left: (attribute) @capture (#not-match? @capture "^self"))'
            ),
            InlineNode(
                '(for_statement left: (identifier) @capture (#not-eq? @capture "self"))'
            ),
            InlineNode(
                '(for_statement left: (pattern_list (identifier) @capture) (#not-eq? @capture "self"))'
            ),
            InlineNode(
                '(for_statement left: (tuple_pattern (identifier) @capture) (#not-eq? @capture "self"))'
            ),
        },
        function_args = {
            InlineNode(
                '(function_definition (parameters (identifier) @capture) (#not-eq? @capture "self"))'
            ),
            InlineNode(
                '(function_definition (parameters (default_parameter (identifier) @capture)) (#not-eq? @capture "self"))'
            ),
            InlineNode(
                '(function_definition (parameters (typed_parameter (identifier) @capture)) (#not-eq? @capture "self"))'
            ),
            InlineNode(
                '(function_definition (parameters (typed_default_parameter (identifier) @capture)) (#not-eq? @capture "self"))'
            ),
        },
        local_var_values = {
            InlineNode(
                "(assignment right: (expression_list (_) @tmp_capture))"
            ),
            InlineNode("(assignment right: (_) @tmp_capture)"),
        },
        local_declarations = {
            InlineNode("(assignment) @tmp_capture"),
        },
        valid_class_nodes = {
            class_definition = 0,
        },
        debug_paths = {
            class_definition = FieldNode("name"),
            function_definition = FieldNode("name"),
        },
        statements = {
            InlineNode("(expression_statement) @tmp_capture"),
            InlineNode("(return_statement) @tmp_capture"),
            InlineNode("(if_statement) @tmp_capture"),
            InlineNode("(for_statement) @tmp_capture"),
            InlineNode("(while_statement) @tmp_capture"),
            InlineNode("(assignment) @tmp_capture"),
            InlineNode("(with_statement) @tmp_capture"),
        },
        indent_scopes = {
            module = true,
            function_definition = true,
            for_statement = true,
            if_statement = true,
        },
        ident_with_type = {
            InlineFilteredNode("(_ (identifier) @ident type: (type) @type)"),
        },
        function_body = {
            InlineNode("(function_definition (block (_) @tmp_capture))"),
        },
        return_statement = {
            InlineNode("(return_statement) @tmp_capture"),
        },
        return_values = {
            InlineNode("(return_statement (expression_list (_) @tmp_capture))"),
        },
        function_references = {
            InlineNode("(call function: (identifier) @tmp_capture)"),
        },
        caller_args = {
            InlineNode(
                "(call function: (identifier) arguments: (argument_list (_) @tmp_capture))"
            ),
        },
        is_return_statement = function(statement)
            return vim.startswith(vim.trim(statement), "return ")
        end,
        reference_filter = function(node)
            local parent = node:parent()
            if not parent then
                return true
            end
            if parent:type() == "default_parameter" then
                return false
            end
            if parent:type() == "keyword_argument" then
                return parent:field("value")[1] == node
            end
            return true
        end,
        include_end_of_line = true,
    }
    local ts = TreeSitter:new(config, bufnr)

    return ts
end

return Python
