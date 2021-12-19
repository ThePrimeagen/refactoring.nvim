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
            TreeSitter.version_flags.Classes
        ),
        filetype = ft,
        bufnr = bufnr,
        block_scope = {
            block = true,
        },
        variable_scope = {
            short_var_declaration = true,
        },
        scope_names = {
            function_declaration = "function",
            method_declaration = "function",
        },
        class_names = {
            method_declaration = 0,
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
        require_class_name = true,
        require_class_type = true,
    }, bufnr)
end

return Golang
