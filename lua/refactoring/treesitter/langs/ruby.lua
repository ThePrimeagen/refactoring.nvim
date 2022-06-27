local TreeSitter = require("refactoring.treesitter.treesitter")
local Nodes = require("refactoring.treesitter.nodes")
local FieldNode = Nodes.FieldNode
local InlineNode = Nodes.InlineNode

local Ruby = {}

function Ruby.new(bufnr, ft)
    return TreeSitter:new({
        filetype = ft,
        bufnr = bufnr,
        scope_names = {
            method = "function",
        },
        block_scope = {
            method = true,
        },
        indent_scopes = {
            method = true,
        },
        local_var_names = {
            InlineNode("(assignment left: (_) @tmp_capture)"),
        },
        local_var_values = {
            InlineNode("(assignment right: (_) @tmp_capture)"),
        },
        local_declarations = {
            InlineNode("((assignment) @tmp_capture)"),
        },
        statements = {
            InlineNode("(binary) @tmp_capture"),
            InlineNode("(return) @tmp_capture"),
            InlineNode("(assignment) @tmp_capture"),
        },
        function_args = {
            InlineNode(
                "(method parameters: (method_parameters (_) @tmp_capture))"
            ),
        },
        -- FIX: Seems to forget "end" when extracting a block
        function_body = {
            InlineNode(
                "((method name: (identifier) (method_parameters)? (_)(_)? @tmp_capture))"
            ),
            InlineNode("(method !parameters name: (_)(_) @tmp_capture)"),
        },
        valid_class_nodes = {
            class = 1,
        },
    }, bufnr)
end

return Ruby
