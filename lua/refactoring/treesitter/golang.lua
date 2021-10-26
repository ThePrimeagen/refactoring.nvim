local TreeSitter = require("refactoring.treesitter.treesitter")
local Bits = require("refactoring.bits")
local Version = require("refactoring.treesitter.version")

local Golang = {}

function Golang.new(bufnr, ft)
    return TreeSitter:new({
        version = Bits.bor(Version.Scopes, Version.Locals),
        filetype = ft,
        bufnr = bufnr,
        scope_names = {
            function_declaration = "function",
        },
    }, bufnr)
end

return Golang
