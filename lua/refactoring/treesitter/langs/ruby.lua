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
            class = "class",
            method = "function",
        },
        indent_scopes = {
            class = true,
            method = true,
        },
        local_var_names = {
            InlineNode("(assignment left: (_) @tmp_capture)"),
        },
        local_var_values = {
            InlineNode("(assignment right: (_) @tmp_capture)"),
        },
        function_scopes = {
            method = "function",
        },
        function_args = {
            InlineNode(
                "(method parameters: (method_parameters (identifier) @tmp_capture))"
            ),
        },
        function_body = {
            InlineNode("(assignment left: (_) @tmp_capture)"),
            InlineNode("(assignment right: (_) @tmp_capture)"),
        },
        local_declarations = {
            InlineNode("((assignment) @tmp_capture)"),
        },
        class_names = {
            InlineNode(
                "(class name: (constant) @tmp_capture)"
            ),
        },
        valid_class_nodes = {
            class = 0,
        },
    }, bufnr)
end

return Ruby
