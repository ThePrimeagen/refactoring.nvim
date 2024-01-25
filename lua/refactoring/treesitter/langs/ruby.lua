local TreeSitter = require("refactoring.treesitter.treesitter")
local Nodes = require("refactoring.treesitter.nodes")
local FieldNode = Nodes.FieldNode
local InlineNode = Nodes.InlineNode

---@class TreeSitterInstance
local Ruby = {}

function Ruby.new(bufnr, ft)
    ---@type TreeSitterLanguageConfig
    local config = {
        filetype = ft,
        bufnr = bufnr,
        scope_names = {
            method = "function",
            singleton_method = "function",
        },
        block_scope = {
            method = true,
            singleton_method = true,
            body_statement = true,
        },
        indent_scopes = {
            program = true,
            method = true,
            singleton_method = true,
        },
        variable_scope = {
            assignment = true,
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
            InlineNode("(if) @tmp_capture"),
            InlineNode("(for) @tmp_capture"),
            InlineNode("(while) @tmp_capture"),
            InlineNode("(assignment) @tmp_capture"),
        },
        function_args = {
            InlineNode(
                "(method parameters: (method_parameters (_) @tmp_capture))"
            ),
            InlineNode(
                "(singleton_method parameters: (method_parameters (_) @tmp_capture))"
            ),
        },
        function_body = {
            InlineNode("(method body: (_) @tmp_capture)"),
            InlineNode("(singleton_method body: (_) @tmp_capture)"),
        },
        valid_class_nodes = {
            class = 1,
        },
        debug_paths = {
            module = FieldNode("name"),
            class = FieldNode("name"),
            method = FieldNode("name"),
            singleton_method = FieldNode("name"),
        },
    }
    return TreeSitter:new(config, bufnr)
end

return Ruby
