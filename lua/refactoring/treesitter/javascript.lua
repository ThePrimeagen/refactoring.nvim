local TreeSitter = require("refactoring.treesitter.treesitter")
local Version = require("refactoring.version")

local JavaScript = {}

function JavaScript.new(bufnr, ft)
    return TreeSitter:new({
        version = Version:new(TreeSitter.version_flags.Scopes, TreeSitter.version_flags.Locals),
        filetype = ft,
        bufnr = bufnr,
        scope_names = {
            program = "program",
            function_declaration = "function",
            method_definition = "function",
            arrow_function = "function",
            class_declaration = "class",
        },
    }, bufnr)
end

return JavaScript
