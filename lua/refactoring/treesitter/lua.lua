local TreeSitter = require("refactoring.treesitter.treesitter")
local Bits = require("refactoring.bits")
local Version = require("refactoring.treesitter.version")

local Lua = {}

function Lua.new(bufnr, ft)
    return TreeSitter:new({
        version = Bits.bor(Version.Scopes, Version.Locals),
        filetype = ft,
        bufnr = bufnr,
        scope_names = {
            program = "program",
            local_function = "function",
            ["function"] = "function",
            function_definition = "function",
        },
    }, bufnr)
end

return Lua
