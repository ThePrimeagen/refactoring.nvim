local TreeSitter = require("refactoring.treesitter.treesitter")

local Nodes = require("refactoring.treesitter.nodes")
local FieldNode = Nodes.FieldNode
local StringNode = Nodes.StringNode
local QueryNode = Nodes.QueryNode
local InlineNode = Nodes.InlineNode

local special_nodes = {
    "method_index_expression",
    "dot_index_expression",
}

---@class TreeSitterInstance
local Lua = {}

function Lua.new(bufnr, ft)
    ---@type TreeSitterLanguageConfig
    local config = {
        filetype = ft,
        bufnr = bufnr,
        scope_names = {
            program = "program",
            local_function = "function",
            ["function_declaration"] = "function",
            function_definition = "function",
            chunk = "chunk",
        },
        block_scope = {
            block = true,
            chunk = true,
        },
        variable_scope = {
            variable_declaration = true,
            local_variable_declaration = true,
        },
        local_var_names = {
            InlineNode(
                "(variable_declaration (assignment_statement (variable_list name: (identifier) @definition.local_name)))"
            ),
            InlineNode(
                "(variable_declaration (variable_list name: (identifier) @definition.local_name))"
            ),
            InlineNode(
                '(assignment_statement (variable_list (dot_index_expression) @capture) (#not-match? @capture "^self"))'
            ),
            InlineNode(
                "(for_generic_clause (variable_list name: (identifier) @definition.local_name))"
            ),
            InlineNode(
                "(for_numeric_clause name: (identifier) @definition.var)"
            ),
        },
        function_args = {
            InlineNode("((parameters (identifier) @tmp_capture))"),
        },
        local_var_values = {
            InlineNode(
                " (variable_declaration (assignment_statement (expression_list value:((_) @definition.local_name)))) "
            ),
        },
        local_declarations = {
            InlineNode("(variable_declaration) @tmp_capture"),
        },
        debug_paths = {
            class_specifier = FieldNode("name"),
            function_definition = StringNode("function"),
            function_declaration = QueryNode(
                "(function_declaration name: [(identifier) (dot_index_expression) (method_index_expression)] @name)"
            ),
            ["function"] = QueryNode("(function (function_name) @name)"),
            ["local_function"] = QueryNode(
                "(local_function (identifier) @name)"
            ),
            if_statement = StringNode("if"),
            repeat_statement = StringNode("repeat"),
            for_in_statement = StringNode("for"),
            for_statement = StringNode("for"),
            while_statement = StringNode("while"),
        },
        indent_scopes = {
            for_statement = true,
            if_statement = true,
            while_statement = true,
            function_declaration = true,
            function_definition = true,
        },
        statements = {
            InlineNode("(return_statement) @tmp_capture"),
            InlineNode("(if_statement) @tmp_capture"),
            InlineNode("(for_statement) @tmp_capture"),
            InlineNode("(do_statement) @tmp_capture"),
            InlineNode("(repeat_statement) @tmp_capture"),
            InlineNode("(while_statement) @tmp_capture"),
            InlineNode("(variable_declaration) @tmp_capture"),
            InlineNode("(assignment_statement) @tmp_capture"),
            InlineNode("(function_call) @tmp_capture"),
        },
        function_body = {
            InlineNode("(function_declaration (block (_) @tmp_capture))"),
        },
        return_statement = {
            InlineNode("(return_statement) @tmp_capture"),
        },
        return_values = {
            InlineNode("(return_statement (expression_list (_) @tmp_capture))"),
        },
        function_references = {
            InlineNode("(function_call name: (identifier) @tmp_capture)"),
        },
        caller_args = {
            InlineNode(
                "(function_call arguments: (arguments (_) @tmp_capture))"
            ),
        },
        is_return_statement = function(statement)
            return vim.startswith(vim.trim(statement), "return ")
        end,
        should_check_parent_node_print_var = function(parent_type)
            return vim.tbl_contains(special_nodes, parent_type)
        end,
        reference_filter = function(node)
            local parent = node:parent()
            if not parent then
                return true
            end
            -- foo.foo
            -- ^
            if parent:type() == "dot_index_expression" then
                return parent:field("table")[1] == node
            -- {foo = foo}
            --        ^
            elseif parent:type() == "field" then
                return parent:field("value")[1] == node
            end
            return true
        end,
    }
    return TreeSitter:new(config, bufnr)
end

return Lua
