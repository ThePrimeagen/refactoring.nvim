local TreeSitter = require("refactoring.treesitter.treesitter")
local Nodes = require("refactoring.treesitter.nodes")
local FieldNode = Nodes.FieldNode
local InlineNode = Nodes.InlineNode

local Python = {}

function Python.new(bufnr, ft)
    local ts = TreeSitter:new({
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
            InlineNode("(assignment left: (_ (_) @tmp_capture))"),
            InlineNode("(assignment left: (_) @tmp_capture)"),
            InlineNode(
                "(for_statement left: (identifier) @definition.local_name)"
            ),
        },
        function_args = {
            InlineNode(
                "((function_definition (parameters (identifier) @tmp_capture)))"
            ),
            InlineNode(
                "((function_definition (parameters (default_parameter (identifier) @tmp_capture))))"
            ),
            InlineNode(
                "((function_definition (parameters (typed_parameter (identifier) @tmp_capture))))"
            ),
            InlineNode(
                "((function_definition (parameters (typed_default_parameter (identifier) @tmp_capture))))"
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
    }, bufnr)

    -- overriding function
    function ts.get_arg_type_key(arg)
        return arg .. ":"
    end

    return ts
end

return Python
