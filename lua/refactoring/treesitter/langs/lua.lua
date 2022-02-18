local TreeSitter = require("refactoring.treesitter.treesitter")
local Version = require("refactoring.version")

local Nodes = require("refactoring.treesitter.nodes")
local FieldNode = Nodes.FieldNode
local StringNode = Nodes.StringNode
local QueryNode = Nodes.QueryNode
local InlineNode = Nodes.InlineNode

local Lua = {}

function Lua.new(bufnr, ft)
    return TreeSitter:new({
        version = Version:new(
            TreeSitter.version_flags.Scopes,
            TreeSitter.version_flags.Locals
        ),
        filetype = ft,
        bufnr = bufnr,
        scope_names = {
            program = "program",
            local_function = "function",
            ["function_declaration"] = "function",
            function_definition = "function",
        },
        block_scope = {
            block = true,
        },
        variable_scope = {
            variable_declaration = true,
            local_variable_declaration = true,
        },
        local_var_names = {
            InlineNode(
                "( variable_declaration ( assignment_statement ( variable_list name:((identifier) @definition.local_name)))) "
            ),
        },
        function_args = {
            InlineNode("((parameters (identifier) @tmp_capture))"),
        },
        local_var_values = {
            InlineNode(
                " ( variable_declaration ( assignment_statement ( expression_list value:((_) @definition.local_name)))) "
            ),
        },
        local_declarations = {
            InlineNode("(variable_declaration) @tmp_capture"),
        },
        debug_paths = {
            class_specifier = FieldNode("name"),
            function_definition = StringNode("function"),
            function_declaration = QueryNode(
                "(function_declaration name: (identifier) @name)"
            ),
            ["function"] = QueryNode("(function (function_name) @name)"),
            ["local_function"] = QueryNode(
                "(local_function (identifier) @name)"
            ),
            if_statement = StringNode("if"),
            repeat_statement = StringNode("repeat"),
            for_in_statement = StringNode("for"),
            for_statement = StringNode("for"),
            while_statement = StringNode("while"),
        },
        statements = {
            InlineNode("(return_statement) @tmp_capture"),
            InlineNode("(if_statement) @tmp_capture"),
            InlineNode("(for_statement) @tmp_capture"),
            InlineNode("(do_statement) @tmp_capture"),
            InlineNode("(repeat_statement) @tmp_capture"),
            InlineNode("(while_statement) @tmp_capture"),
            InlineNode("(variable_declaration) @tmp_capture"),
        },
    }, bufnr)
end

return Lua
