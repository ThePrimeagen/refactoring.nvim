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
        },
        to_string = function(self, node)
            return self.debug_path_names[node:type()] or "(unknown node)"
        end,
    }, bufnr)
end

return Typescript
