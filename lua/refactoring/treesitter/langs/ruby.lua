local TreeSitter = require("refactoring.treesitter.treesitter")
local Nodes = require("refactoring.treesitter.nodes")
local FieldNode = Nodes.FieldNode
local StringNode = Nodes.StringNode
local InlineNode = Nodes.InlineNode

local ruby = {}

function ruby.new(bufnr, ft)
    return TreeSitter:new({
        filetype = ft,
        bufnr = bufnr,
        scope_names = {
            program = "program",
            method_declaration = "def",
            function_declaration = "def",
            function_definition = "def",
            class_declaration = "class",
        },
        indent_scopes = {
            function_declaration = true,
            function_definition = true,
        },
        variable_scope = {
            variable_declaration = true,
            local_variable_declaration = false,
        },
        function_args = {
            InlineNode(
                "((method (method_parameters (identifier) @tmp_capture)))"
            ),
        },
        local_var_names = {
            InlineNode(
                "( assignment (identifier) @definition.local_name)"
            ),
        },
        local_declarations = {
            InlineNode("(assignment) @tmp_capture"),
        },
    }, bufnr)
end

return ruby
