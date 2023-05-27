local TreeSitter = require("refactoring.treesitter.treesitter")
local Nodes = require("refactoring.treesitter.nodes")
local FieldNode = Nodes.FieldNode
local StringNode = Nodes.StringNode
local InlineNode = Nodes.InlineNode

local special_nodes = {
    "variable_name",
}

---@type TreeSitterInstance
local Php = {}

function Php.new(bufnr, ft)
    ---@type TreeSitterLanguageConfig
    local config = {
        filetype = ft,
        bufnr = bufnr,
        scope_names = {
            program = "program",
            method_declaration = "function",
            class_declaration = "class",
        },
        block_scope = {
            compound_statement = true,
        },
        variable_scope = {
            expression_statement = true,
        },
        indent_scopes = {
            program = true,
            function_declaration = true,
            expression_statement = true,
            method_declaration = true,
            arrow_function = true,
            class_declaration = true,
            if_statement = true,
            for_statement = true,
            for_in_statement = true,
            while_statement = true,
            do_statement = true,
        },
        local_var_names = {
            InlineNode(
                "(expression_statement (assignment_expression left: (variable_name (name) @tmp_capture)))"
            ),
        },
        function_args = {
            InlineNode(
                "(formal_parameters (simple_parameter (variable_name) @tmp_capture))"
            ),
        },
        local_var_values = {
            InlineNode(
                "(expression_statement (assignment_expression (binary_expression) @tmp_capture))"
            ),
        },
        local_declarations = {
            InlineNode(
                "(expression_statement (assignment_expression)) @definition.local_declarator"
            ),
        },
        debug_paths = {
            function_definition = FieldNode("name"),
            class_declaration = FieldNode("name"),
            method_declaration = FieldNode("name"),
            if_statement = StringNode("if"),
            for_statement = StringNode("for"),
            for_in_statement = StringNode("for_in"),
            while_statement = StringNode("while"),
            do_statement = StringNode("do"),
        },
        statements = {
            InlineNode("(expression_statement) @tmp_capture"),
            InlineNode("(return_statement) @tmp_capture"),
            InlineNode("(if_statement) @tmp_capture"),
            InlineNode("(for_statement) @tmp_capture"),
            InlineNode("(do_statement) @tmp_capture"),
            InlineNode("(assignment_expression) @tmp_capture"),
        },
        function_body = {
            InlineNode("(compound_statement) @tmp_capture"),
        },
        ---@param parent_type string
        ---@return boolean
        should_check_parent_node = function(parent_type)
            return vim.tbl_contains(special_nodes, parent_type)
        end,
    }
    return TreeSitter:new(config, bufnr)
end

return Php
