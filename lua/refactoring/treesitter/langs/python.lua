local TreeSitter = require("refactoring.treesitter.treesitter")
local Version = require("refactoring.version")
local Nodes = require("refactoring.treesitter.nodes")
local FieldNode = Nodes.FieldNode
local InlineNode = Nodes.InlineNode

local Python = {}

function Python.new(bufnr, ft)
    return TreeSitter:new({
        version = Version:new(
            TreeSitter.version_flags.Scopes,
            TreeSitter.version_flags.Locals,
            TreeSitter.version_flags.Classes,
            TreeSitter.version_flags.Indents
        ),
        filetype = ft,
        bufnr = bufnr,
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
            InlineNode("(assignment left: (_ (_) @tmp_capture))"),
            InlineNode("(assignment left: (_) @tmp_capture)"),
        },
        local_var_values = {
            InlineNode("(assignment right: (_) @tmp_capture)"),
        },
        local_declarations = {
            InlineNode("((assignment) @tmp_capture)"),
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
        },
        allow_indenting_task = true,
        indent_scopes = {
            function_definition = true,
            for_statement = true,
        },
    }, bufnr)
end

return Python
