local TreeSitter = require("refactoring.treesitter.treesitter")

local Nodes = require("refactoring.treesitter.nodes")
local FieldNode = Nodes.FieldNode
local StringNode = Nodes.StringNode
local TakeFirstNode = Nodes.TakeFirstNode
local QueryNode = Nodes.QueryNode
local InlineNode = Nodes.InlineNode
local InlineFilteredNode = Nodes.InlineFilteredNode

---@class TreeSitterInstance
local C = {}

function C.new(bufnr, ft)
    ---@type TreeSitterLanguageConfig
    local config = {
        filetype = ft,
        bufnr = bufnr,
        scope_names = {
            translation_unit = "program",
            function_definition = "function",
            class_specifier = "class",
        },
        block_scope = {
            function_definition = true,
            compound_statement = true,
        },
        variable_scope = {
            declaration = true,
        },
        local_var_names = {
            InlineNode(
                "(declaration declarator: (init_declarator declarator: (_) @tmp_capture))"
            ),
        },
        function_args = {
            InlineNode(
                "((parameter_list (parameter_declaration declarator: (_) @tmp_capture)))"
            ),
        },
        local_var_values = {
            InlineNode(
                "(declaration declarator: (init_declarator value: (_) @tmp_capture))"
            ),
        },
        local_declarations = {
            InlineNode("((declaration) @tmp_capture)"),
        },
        indent_scopes = {
            if_statement = true,
            for_statement = true,
            do_statement = true,
            while_statement = true,
            function_definition = true,
        },
        debug_paths = {
            class_specifier = FieldNode("name"),
            function_definition = TakeFirstNode(
                QueryNode(
                    "(function_declarator (field_identifier) @tmp_capture)"
                ),
                QueryNode("(function_declarator (identifier) @tmp_capture)"),
                StringNode("function")
            ),
            if_statement = StringNode("if"),
            for_statement = StringNode("for"),
            while_statement = StringNode("while"),
            do_statement = StringNode("do"),
        },
        statements = {
            InlineNode("(expression_statement) @tmp_capture"),
            InlineNode("(return_statement) @tmp_capture"),
            InlineNode("(if_statement) @tmp_capture"),
            InlineNode("(for_statement) @tmp_capture"),
            InlineNode("(do_statement) @tmp_capture"),
            InlineNode("(while_statement) @tmp_capture"),
            InlineNode("(declaration) @tmp_capture"),
            InlineNode("(function_definition) @tmp_capture"),
        },
        ident_with_type = {
            InlineFilteredNode(
                "(_ type: (primitive_type)@type declarator: (init_declarator (identifier)@ident))"
            ),
            InlineFilteredNode(
                "(_ type: (primitive_type)@type declarator: (identifier) @ident)"
            ),
        },
        function_body = {
            InlineNode(
                "(function_definition (compound_statement (_) @tmp_capture))"
            ),
        },
        return_statement = {
            InlineNode("(return_statement) @tmp_capture"),
        },
        return_values = {
            InlineNode("(return_statement (_) @tmp_capture)"),
        },
        function_references = {
            InlineNode("(call_expression function: (identifier) @tmp_capture)"),
        },
        caller_args = {
            InlineNode(
                "(call_expression arguments: (argument_list (_) @tmp_capture))"
            ),
        },
        require_param_types = true,
        is_return_statement = function(statement)
            return vim.startswith(vim.trim(statement), "return")
        end,
    }
    return TreeSitter:new(config, bufnr)
end

return C
