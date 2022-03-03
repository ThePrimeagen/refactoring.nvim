local TreeSitter = require("refactoring.treesitter.treesitter")
local Version = require("refactoring.version")
local Nodes = require("refactoring.treesitter.nodes")
local FieldNode = Nodes.FieldNode
local StringNode = Nodes.StringNode
local InlineNode = Nodes.InlineNode

local Typescript = {}

function Typescript.new(bufnr, ft)
    return TreeSitter:new({
        version = Version:new(
            TreeSitter.version_flags.Scopes,
            TreeSitter.version_flags.Locals,
            TreeSitter.version_flags.Indents
        ),
        filetype = ft,
        bufnr = bufnr,
        allow_indenting_task = true,
        scope_names = {
            program = "program",
            function_declaration = "function",
            method_definition = "function",
            arrow_function = "function",
            class_declaration = "class",
        },
        block_scope = {
            statement_block = true,
        },
        variable_scope = {
            lexical_declaration = true,
        },
        indent_scopes = {
            program = true,
            function_declaration = true,
            method_definition = true,
            arrow_function = true,
            class_declaration = true,
            if_statement = true,
            for_statement = true,
            for_in_statement = true,
            while_statement = true,
            do_statement = true,
        },
        local_var_names = {
            InlineNode(
                "(lexical_declaration (variable_declarator name: (_) @tmp_capture))"
            ),
        },
        function_args = {
            InlineNode(
                "((formal_parameters (required_parameter (identifier) @tmp_capture)))"
            ),
            InlineNode(
                "((formal_parameters (optional_parameter (identifier) @tmp_capture)))"
            ),
            InlineNode("(for_in_statement left: (identifier) @tmp_capture)"),
        },
        local_var_values = {
            InlineNode(
                "(lexical_declaration (variable_declarator value: (_) @tmp_capture))"
            ),
        },
        local_declarations = {
            InlineNode("(lexical_declaration) @definition.local_declarator"),
        },
        debug_paths = {
            function_declaration = FieldNode("name"),
            method_definition = FieldNode("name"),
            class_declaration = FieldNode("name"),
            abstract_class_declaration = FieldNode("name"),
            arrow_function = function(node)
                return FieldNode("name")(node:parent(), "(anon)")
            end,
            if_statement = StringNode("if"),
            for_statement = StringNode("for"),
            for_in_statement = StringNode("for_in"),
            while_statement = StringNode("while"),
            do_statement = StringNode("do"),
        },
        statements = {
            InlineNode("(expression_statement) @tmp_capture"),
            InlineNode("(return_statement) @tmp_capture"),
            InlineNode("(if_statement) @tmp_capture"),
            InlineNode("(for_statement) @tmp_capture"),
            InlineNode("(for_in_statement) @tmp_capture"),
            InlineNode("(do_statement) @tmp_capture"),
            InlineNode("(while_statement) @tmp_capture"),
            InlineNode("(lexical_declaration) @tmp_capture"),
        },
    }, bufnr)
end

return Typescript
