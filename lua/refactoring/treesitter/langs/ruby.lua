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
        indent_scopes = {
            method = true,
        },
        local_var_names = {
            InlineNode("(assignment left: (_) @tmp_capture)"),
        },
        local_var_values = {
            InlineNode("(assignment right: (_) @tmp_capture)"),
        },
        function_args = {
            InlineNode(
                "(method parameters: (method_parameters (identifier) @tmp_capture))"
            ),
        },
        local_declarations = {
            InlineNode("((assignment) @tmp_capture)"),
        },
        valid_class_nodes = {
            class = 1,
        },
    }, bufnr)
end

return Ruby
