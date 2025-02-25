local TreeSitter = require("refactoring.treesitter.treesitter")
local Nodes = require("refactoring.treesitter.nodes")
local FieldNode = Nodes.FieldNode
local StringNode = Nodes.StringNode
local InlineNode = Nodes.InlineNode
local InlineFilteredNode = Nodes.InlineFilteredNode

---@class TreeSitterInstance
local TypescriptReact = {}

function TypescriptReact.new(bufnr, ft)
    ---@type TreeSitterLanguageConfig
    local config = {
        filetype = ft,
        bufnr = bufnr,
        require_param_types = true,
        scope_names = {
            program = "program",
            function_declaration = "function",
            method_definition = "function",
            arrow_function = "function",
            class_declaration = "class",
        },
        block_scope = {
            statement_block = true,
        },
        variable_scope = {
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
                "((formal_parameters (required_parameter (identifier) @tmp_capture)))"
            ),
            InlineNode(
                "((formal_parameters (optional_parameter (identifier) @tmp_capture)))"
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
            abstract_class_declaration = FieldNode("name"),
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
            InlineNode("(lexical_declaration) @tmp_capture"),
        },
        ident_with_type = {
            InlineFilteredNode(
                "(_ [name: (identifier) pattern: (identifier)] @ident type: (type_annotation (_) @type))"
            ),
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
    }
    local ts = TreeSitter:new(config, bufnr)

    return ts
end

return TypescriptReact
