local TreeSitter = require("refactoring.treesitter.treesitter")

local Nodes = require("refactoring.treesitter.nodes")
local FieldNode = Nodes.FieldNode
local StringNode = Nodes.StringNode
local TakeFirstNode = Nodes.TakeFirstNode
local QueryNode = Nodes.QueryNode
local InlineNode = Nodes.InlineNode
local InlineFilteredNode = Nodes.InlineFilteredNode

---@class TreeSitterInstance
local CS = {}

function CS.new(bufnr, ft)
    ---@type TreeSitterLanguageConfig
    local config = {
        filetype = ft,
        bufnr = bufnr,
        scope_names = {
            compilation_unit = "program",
            method_declaration = "function",
            local_function_statement = "function",
            class_declaration = "class",
        },
        block_scope = {
            method_declaration = true,
            local_function_statement = true,
            block = true,
        },
        variable_scope = {
            local_declaration_statement = true,
        },
        local_var_names = {
            InlineNode("(variable_declarator name: (_) @tmp_capture)"),
        },
        function_args = {
            InlineNode("(parameter_list (parameter name: (_) @tmp_capture))"),
        },
        local_var_values = {
            InlineNode("(variable_declarator  (_) @tmp_capture . )"),
        },
        local_declarations = {
            InlineNode("(local_declaration_statement) @tmp_capture"),
        },
        indent_scopes = {
            method_declaration = true,
            class_declaration = true,
            if_statement = true,
            for_statement = true,
            foreach_statement = true,
            while_statement = true,
            do_statement = true,
        },
        debug_paths = {
            class_declaration = FieldNode("name"),
            method_declaration = TakeFirstNode(
                QueryNode(
                    "(method_declaration name: (identifier) @tmp_capture)"
                ),
                StringNode("function")
            ),
            if_statement = StringNode("if"),
            for_statement = StringNode("for"),
            foreach_statement = StringNode("foreach"),
            while_statement = StringNode("while"),
            do_statement = StringNode("do"),
        },
        statements = {
            InlineNode("(expression_statement) @tmp_capture"),
            InlineNode("(return_statement) @tmp_capture"),
            InlineNode("(if_statement) @tmp_capture"),
            InlineNode("(for_statement) @tmp_capture"),
            InlineNode("(foreach_statement) @tmp_capture"),
            InlineNode("(do_statement) @tmp_capture"),
            InlineNode("(while_statement) @tmp_capture"),
            InlineNode("(local_declaration_statement) @tmp_capture"),
        },
        ident_with_type = {
            InlineFilteredNode(
                "(_ type: (_) @type (variable_declarator (identifier) @ident))"
            ),
            InlineFilteredNode("(_ type: (_) @type name: (identifier) @ident)"),
        },
        function_body = {
            InlineNode("(method_declaration (block (_) @tmp_capture))"),
        },
        require_class_name = true,
        require_class_type = true,
        require_param_types = true,
    }
    return TreeSitter:new(config, bufnr)
end

return CS
