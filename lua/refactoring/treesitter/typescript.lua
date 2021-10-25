local TreeSitter = require("refactoring.treesitter.treesitter")
local Bits = require("refactoring.bits")
local Version = require("refactoring.treesitter.version")

local Typescript = {}

function Typescript.new(bufnr, ft)
    return TreeSitter:new({
        version = Bits.bor(Version.Scopes, Version.Locals),
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
