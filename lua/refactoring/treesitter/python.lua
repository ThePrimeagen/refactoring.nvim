local TreeSitter = require("refactoring.treesitter.treesitter")
local Bits = require("refactoring.bits")
local Version = require("refactoring.treesitter.version")

local Python = {}

function Python.new(bufnr, ft)
    return TreeSitter:new({
        version = Bits.bor(Version.Scopes, Version.Locals),
        filetype = ft,
        bufnr = bufnr,
        scope_names = {
            function_definition = "function",
        },
    }, bufnr)
end

return Python
