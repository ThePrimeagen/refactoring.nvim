local TreeSitter = require("refactoring.treesitter.treesitter")

local Typescript = {}

function Typescript.new(bufnr, ft)
    return TreeSitter:new({
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

return Typescript
