local TreeSitter = require("refactoring.treesitter.treesitter")
local Nodes = require("refactoring.treesitter.nodes")
local FieldNode = Nodes.FieldNode
local InlineNode = Nodes.InlineNode

---@type TreeSitterInstance
local Python = {}

function Python.new(bufnr, ft)
    ---@type TreeSitterLanguageConfig
    local config = {
        filetype = ft,
        bufnr = bufnr,
        require_param_types = true,
        scope_names = {
            function_definition = "function",
            module = "program",
        },
        block_scope = {
            block = true,
            function_definition = true,
            module = true,
        },
        variable_scope = {
            assignment = true,
        },
        local_var_names = {
            InlineNode(
                '((assignment left: (_ (_) @capture)) (#not-eq? @capture "self"))'
            ),
            InlineNode(
                '((assignment left: (_) @capture) (#not-eq? @capture "self"))'
            ),
            InlineNode(
                '((for_statement left: (identifier) @capture) (#not-eq? @capture "self"))'
            ),
        },
        function_args = {
            InlineNode(
                '((function_definition (parameters (identifier) @capture)) (#not-eq? @capture "self"))'
            ),
            InlineNode(
                '((function_definition (parameters (default_parameter (identifier) @capture))) (#not-eq? @capture "self"))'
            ),
            InlineNode(
                '((function_definition (parameters (typed_parameter (identifier) @capture))) (#not-eq? @capture "self"))'
            ),
            InlineNode(
                '((function_definition (parameters (typed_default_parameter (identifier) @capture))) (#not-eq? @capture "self"))'
            ),
        },
        local_var_values = {
            InlineNode("(assignment right: (_ (_) @tmp_capture))"),
            InlineNode("(assignment right: (_) @tmp_capture)"),
        },
        local_declarations = {
            InlineNode("((assignment) @tmp_capture)"),
        },
        valid_class_nodes = {
            class_definition = 0,
        },
        debug_paths = {
            class_definition = FieldNode("name"),
            function_definition = FieldNode("name"),
        },
        statements = {
            InlineNode("(expression_statement) @tmp_capture"),
            InlineNode("(return_statement) @tmp_capture"),
            InlineNode("(if_statement) @tmp_capture"),
            InlineNode("(for_statement) @tmp_capture"),
            InlineNode("(while_statement) @tmp_capture"),
            InlineNode("(assignment) @tmp_capture"),
        },
        indent_scopes = {
            module = true,
            function_definition = true,
            for_statement = true,
            if_statement = true,
        },
        function_scopes = {
            function_definition = true,
            if_statement = true,
            module = true,
        },
        parameter_list = {
            InlineNode(
                "(function_definition parameters: (parameters((typed_parameter) @capture)))"
            ),
            InlineNode(
                "(function_definition parameters: (parameters((typed_default_parameter) @capture)))"
            ),
        },
        function_body = {
            InlineNode("(block (_) @tmp_capture)"),
        },
        class_vars = {
            InlineNode(
                "(expression_statement (assignment left: ((attribute attribute: ((identifier) @capture)))))"
            ),
        },
        include_end_of_line = true,
    }
    local ts = TreeSitter:new(config, bufnr)

    -- overriding function
    ---@param arg string
    ---@return string
    function ts.get_arg_type_key(arg)
        return arg .. ":"
    end

    return ts
end

return Python
