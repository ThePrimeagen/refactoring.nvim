local TreeSitter = require("refactoring.treesitter.treesitter")

---@class refactor.TreeSitterInstance
local Vue = {}

function Vue.new(bufnr, ft)
    ---@type refactor.TreeSitterLanguageConfig
    local config = {
        filetype = ft,
        bufnr = bufnr,
        scope_names = {},
        block_scope = {},
        variable_scope = {},
        indent_scopes = {},
        valid_class_nodes = {},
        local_var_names = {},
        function_args = {},
        local_var_values = {},
        local_declarations = {},
        debug_paths = {},
        statements = {},
        ident_with_type = {},
        function_body = {},
        return_values = {},
        caller_args = {},
        return_statement = {},
        function_references = {},
    }
    local ts = TreeSitter:new(config, bufnr)

    return ts
end

return Vue
