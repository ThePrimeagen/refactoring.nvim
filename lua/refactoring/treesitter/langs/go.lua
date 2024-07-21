local TreeSitter = require("refactoring.treesitter.treesitter")
local Nodes = require("refactoring.treesitter.nodes")
local FieldNode = Nodes.FieldNode
local InlineNode = Nodes.InlineNode
local InlineFilteredNode = Nodes.InlineFilteredNode

local special_nodes = {
    "selector_expression",
}

---@class TreeSitterInstance
local Golang = {}

function Golang.new(bufnr, ft)
    ---@type TreeSitterLanguageConfig
    local config = {
        filetype = ft,
        bufnr = bufnr,
        block_scope = {
            block = true,
        },
        variable_scope = {
            short_var_declaration = true,
            var_declaration = true,
        },
        indent_scopes = {
            function_declaration = true,
            method_declaration = true,
        },
        scope_names = {
            function_declaration = "function",
            method_declaration = "function",
            func_literal = "function",
            method = "program",
        },
        valid_class_nodes = {
            method_declaration = 0,
        },
        class_names = {
            InlineNode(
                "(method_declaration receiver: (parameter_list) @tmp_capture)"
            ),
        },
        class_type = {
            InlineNode(
                "(method_declaration receiver: (parameter_list (parameter_declaration name: (identifier) @tmp_capture)))"
            ),
        },
        local_var_names = {
            InlineNode(
                "(short_var_declaration left: (expression_list (identifier) @tmp_capture))"
            ),
            InlineNode(
                "(var_declaration (var_spec name: (identifier) @tmp_capture))"
            ),
        },
        local_declarations = {
            InlineNode("(short_var_declaration) @tmp_capture"),
            InlineNode("(var_declaration) @tmp_capture"),
        },
        local_var_values = {
            InlineNode(
                "(var_declaration (var_spec value: (expression_list (_) @tmp_capture)))"
            ),
            InlineNode("(short_var_declaration right: (_ (_) @tmp_capture))"),
        },
        debug_paths = {
            function_declaration = FieldNode("name"),
            method_declaration = FieldNode("name"),
        },
        statements = {
            InlineNode("(short_var_declaration) @tmp_capture"),
            InlineNode("(return_statement) @tmp_capture"),
            InlineNode("(if_statement) @tmp_capture"),
            InlineNode("(for_statement) @tmp_capture"),
            InlineNode("(call_expression) @tmp_capture"),
            InlineNode("(assignment_statement) @tmp_capture"),
            InlineNode("(expression_statement) @tmp_capture"),
        },
        ident_with_type = {
            InlineFilteredNode(
                "(_ name: (identifier) @ident type: (type_identifier) @type)"
            ),
        },
        function_args = {
            InlineNode(
                "(function_declaration parameters: (parameter_list (parameter_declaration (identifier) @tmp_capture)))"
            ),
            InlineNode(
                "(method_declaration parameters: (parameter_list (parameter_declaration name: (identifier) @definition.function_argument)))"
            ),
        },
        function_body = {
            InlineNode("(function_declaration (block (_) @tmp_capture))"),
            InlineNode("(method_declaration (block (_) @tmp_capture))"),
        },
        return_statement = {
            InlineNode("(return_statement) @tmp_capture"),
        },
        return_values = {
            InlineNode("(return_statement (expression_list (_) @tmp_capture))"),
        },
        function_references = {
            InlineNode("(call_expression function: (identifier) @tmp_capture)"),
        },
        caller_args = {
            InlineNode(
                "(call_expression arguments: (argument_list (_) @tmp_capture))"
            ),
        },
        require_class_name = true,
        require_class_type = true,
        require_param_types = true,
        is_return_statement = function(statement)
            return vim.startswith(vim.trim(statement), "return ")
        end,
        should_check_parent_node = function(parent_type)
            return vim.tbl_contains(special_nodes, parent_type)
        end,
    }
    return TreeSitter:new(config, bufnr)
end

return Golang
