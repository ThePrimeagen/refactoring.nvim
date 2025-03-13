local TreeSitter = require("refactoring.treesitter.treesitter")
local Nodes = require("refactoring.treesitter.nodes")
local FieldNode = Nodes.FieldNode
local StringNode = Nodes.StringNode
local InlineNode = Nodes.InlineNode

---@class refactor.TreeSitterInstance
local JavaScript = {}

function JavaScript.new(bufnr, ft)
    ---@type refactor.TreeSitterLanguageConfig
    local config = {
        filetype = ft,
        bufnr = bufnr,
        scope_names = {
            program = "program",
            function_declaration = "function",
            method_definition = "function",
            arrow_function = "function",
            class_declaration = "class",
        },
        block_scope = {
            statement_block = true,
            function_declaration = true,
            program = true,
        },
        variable_scope = {
            variable_declaration = true,
            lexical_declaration = true,
        },
        indent_scopes = {
            program = true,
            if_statement = true,
            for_statement = true,
            for_in_statement = true,
            do_statement = true,
            while_statement = true,
            function_declaration = true,
            method_definition = true,
            arrow_function = true,
            switch_statement = true,
            switch_case = true,
            class_declaration = true,
        },
        valid_class_nodes = {
            class_declaration = true,
            abstract_class_declaration = true,
        },
        local_var_names = {
            InlineNode(
                "(lexical_declaration (variable_declarator name: (_) @tmp_capture))"
            ),
            InlineNode(
                "(lexical_declaration (variable_declarator name: (array_pattern (identifier) @tmp_capture) ))"
            ),
            InlineNode(
                "(lexical_declaration (variable_declarator name: (object_pattern (shorthand_property_identifier_pattern) @tmp_capture) ))"
            ),
        },
        function_args = {
            InlineNode(
                "(formal_parameters (identifier) @definition.function_argument)"
            ),
            InlineNode(
                "(formal_parameters (assignment_pattern (identifier) @tmp_capture))"
            ),
            InlineNode("(for_in_statement left: (identifier) @tmp_capture)"),
        },
        local_var_values = {
            InlineNode(
                "(lexical_declaration (variable_declarator value: (_) @tmp_capture))"
            ),
        },
        local_declarations = {
            InlineNode("(lexical_declaration) @definition.local_declarator"),
        },
        debug_paths = {
            function_declaration = FieldNode("name"),
            method_definition = FieldNode("name"),
            class_declaration = FieldNode("name"),
            arrow_function = function(node)
                return FieldNode("name")(node:parent(), "(anon)")
            end,
            function_expression = StringNode("(anon)"),
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
            InlineNode("(for_in_statement) @tmp_capture"),
            InlineNode("(do_statement) @tmp_capture"),
            InlineNode("(while_statement) @tmp_capture"),
            InlineNode("(function_declaration) @tmp_capture"),
            InlineNode("(method_definition) @tmp_capture"),
            InlineNode("(arrow_function) @tmp_capture"),
            InlineNode("(switch_statement) @tmp_capture"),
            InlineNode("(switch_case) @tmp_capture"),
            InlineNode("(class_declaration) @tmp_capture"),
            InlineNode("(lexical_declaration) @tmp_capture"),
            InlineNode("(variable_declaration) @tmp_capture"),
        },
        function_body = {
            InlineNode(
                "(method_definition (statement_block (_) @tmp_capture))"
            ),
            InlineNode(
                "(function_declaration (statement_block (_) @tmp_capture))"
            ),
            InlineNode("(arrow_function (statement_block (_) @tmp_capture))"),
        },
        require_special_var_format = true,
        should_check_parent_node = function(node)
            local parent = node:parent()
            if not parent then
                return false
            end
            if
                not vim.tbl_contains({
                    "jsx_element",
                    "jsx_self_closing_element",
                }, parent:type())
            then
                return false
            end

            return true
        end,
        should_check_parent_node_print_var = function(node)
            local parent = node:parent()
            if not parent then
                return false
            end
            local parent_type = parent:type()
            if parent_type == "member_expression" then
                local property_node = parent:field("property")[1]
                if not property_node then
                    return false
                end
                if not property_node:equal(node) then
                    return false
                end
                return true
            elseif parent_type == "call_expression" then
                return true
            else
                return false
            end
        end,
    }
    return TreeSitter:new(config, bufnr)
end

return JavaScript
