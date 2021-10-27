local TreeSitter = require("refactoring.treesitter.treesitter")
local Version = require("refactoring.version")

local Golang = {}

function Golang.new(bufnr, ft)
    return TreeSitter:new({
        version = Version:new(
            TreeSitter.version_flags.Scopes,
            TreeSitter.version_flags.Locals
        ),
        filetype = ft,
        bufnr = bufnr,
        scope_names = {
            function_declaration = "function",
        },
    }, bufnr)
end

return Golang
