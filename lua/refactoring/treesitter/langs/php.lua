local TreeSitter = require("refactoring.treesitter.treesitter")
local Version = require("refactoring.version")
local Nodes = require("refactoring.treesitter.nodes")
local FieldNode = Nodes.FieldNode
local StringNode = Nodes.StringNode
local InlineNode = Nodes.InlineNode

local php = {}

function php.new(bufnr, ft)
    return TreeSitter:new({
        version = Version:new(
            TreeSitter.version_flags.Scopes,
            TreeSitter.version_flags.Locals,
            TreeSitter.version_flags.Indents
        ),
        filetype = ft,
        bufnr = bufnr,
        scope_names = {
            program = "program",
            function_declaration = "function",
            function_definition = "function",
            arrow_function = "function",
            class_declaration = "class",
        },
        block_scope = {
            statement_block = true,
        },
        variable_scope = {
            expression_statement = true,
        },
        indent_scopes = {
            program = true,
            function_declaration = true,
            function_definition = true,
            arrow_function = true,
            class_declaration = true,
            if_statement = true,
            for_statement = true,
            while_statement = true,
            do_statement = true,
        },
        local_var_names = {
            InlineNode(
                "(expression_statement (assignment_expression (variable_name) @tmp_capture))"
            ),
        },
        local_var_values = {
            InlineNode(
                "(expression_statement (assignment_expression (encapsed_string) @tmp_capture))"
            ),
        },
        local_declarations = {
            InlineNode("(expression_statement) @definition.local_declarator"),
        },
        debug_paths = {
            function_declaration = FieldNode("name"),
            function_definition = FieldNode("name"),
            class_declaration = FieldNode("name"),
            arrow_function = function(node)
                return FieldNode("name")(node:parent(), "(anon)")
            end,
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
            InlineNode("(expression_statement) @tmp_capture"),
        },
    }, bufnr)
end

return php
