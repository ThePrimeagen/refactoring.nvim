local ts_utils = require("nvim-treesitter.ts_utils")
local TreeSitter = require("refactoring.treesitter.treesitter")
local Version = require("refactoring.version")

local Typescript = {}

function Typescript.new(bufnr, ft)
    return TreeSitter:new({
        version = Version:new(
            TreeSitter.version_flags.Scopes,
            TreeSitter.version_flags.Locals
        ),
        filetype = ft,
        bufnr = bufnr,
        scope_names = {
            program = "program",
            function_declaration = "function",
            method_definition = "function",
            arrow_function = "function",
            class_declaration = "class",
        },
        debug_path_names = {
            function_declaration = "function",
            method_definition = "function",
            class_declaration = "class",
            arrow_function = "function",
            if_statement = "if",
            for_statement = "for",
            while_statement = "while",
            do_statement = "do",
        },
        to_string = function(self, node)
            local type = node:type()
            local debug_type = self.debug_path_names[type]
            if debug_type == "function" then
                local name_node = node:field("name")[1]

                if name_node then
                    return ts_utils.get_node_text(name_node)[1]
                else
                    if type == "arrow_function" then
                        return "() => {}"
                    end
                    return "function"
                end
            end
            return self.debug_path_names[node:type()] or "(unknown node)"
        end,
    }, bufnr)
end

return Typescript
