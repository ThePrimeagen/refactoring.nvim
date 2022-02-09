local TreeSitter = require("refactoring.treesitter.treesitter")
local Version = require("refactoring.version")
local Nodes = require("refactoring.treesitter.nodes")
local FieldNode = Nodes.FieldNode
local InlineNode = Nodes.InlineNode

local Golang = {}

function Golang.new(bufnr, ft)
    return TreeSitter:new({
        version = Version:new(
            TreeSitter.version_flags.Scopes,
            TreeSitter.version_flags.Locals,
            TreeSitter.version_flags.Classes,
            TreeSitter.version_flags.Indents
        ),
        filetype = ft,
        bufnr = bufnr,
        block_scope = {
            block = true,
        },
        variable_scope = {
            short_var_declaration = true,
        },
        indent_scopes = {
            function_declaration = true,
            method_declaration = true,
        },
        scope_names = {
            function_declaration = "function",
            method_declaration = "function",
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
        },
        parameter_list = {
            InlineNode(
                "(function_declaration parameters: (parameter_list ((parameter_declaration) @tmp_capture)))"
            ),
            InlineNode(
                "(method_declaration parameters: (parameter_list ((parameter_declaration) @tmp_capture)))"
            ),
        },
        function_scopes = {
            function_declaration = "function",
            method_declaration = "function",
            if_statement = true,
        },
        require_class_name = true,
        require_class_type = true,
        require_param_types = true,
        allow_indenting_task = true,
    }, bufnr)
end

return Golang
