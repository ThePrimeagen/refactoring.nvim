local TreeSitter = require("refactoring.treesitter.treesitter")
local Nodes = require("refactoring.treesitter.nodes")
local FieldNode = Nodes.FieldNode
local InlineNode = Nodes.InlineNode

---@class refactor.TreeSitterInstance
local Dart = {}

function Dart.new(bufnr, ft)
    ---@type refactor.TreeSitterLanguageConfig
    local config = {
        filetype = ft,
        bufnr = bufnr,
        scope_names = {
           function_signature = "function",
           function_body = "function",
           block = "function",
        },
        block_scope = {
            function_signature = true,
            function_body = true,
            block = true,
        },
        indent_scopes = {
            program = true,
            ["if_statement"] = true,
            ["for_statement"] = true,
            ["while_statement"] = true,
            function_signature = true,
            method_signature = true,
        },
        variable_scope = {
            local_variable_declaration = true,
        },
        local_var_names = {
            InlineNode("(local_variable_declaration (initialized_variable_definition name: (identifier) @tmp_capture))"),
        },
        local_var_values = {
            InlineNode("(local_variable_declaration (initialized_variable_definition value: (_) @tmp_capture))"),
        },
        local_declarations = {
            InlineNode("((local_variable_declaration) @tmp_capture)"),
        },
       statements = {
    InlineNode("(additive_expression) @tmp_capture"),
    InlineNode("(multiplicative_expression) @tmp_capture"),
    InlineNode("(return_statement) @tmp_capture"),
    InlineNode("(if_statement) @tmp_capture"),
    InlineNode("(for_statement) @tmp_capture"),
    InlineNode("(while_statement) @tmp_capture"),
    InlineNode("(local_variable_declaration) @tmp_capture"),
    InlineNode("(expression_statement) @tmp_capture"),
    InlineNode("(assignment_expression) @tmp_capture"),
},
        function_args = {
            InlineNode("(formal_parameter_list (formal_parameter name: (identifier) @tmp_capture))"),
        },
        function_body = {
            InlineNode("(function_body (_) @tmp_capture)"),
        },
        valid_class_nodes = {
            class_definition = 1,
        },
        debug_paths = {
            class_definition = FieldNode("name"),
            function_signature = FieldNode("name"),
            method_signature = FieldNode("name"),
        },
    }
    return TreeSitter:new(config, bufnr)
end

return Dart