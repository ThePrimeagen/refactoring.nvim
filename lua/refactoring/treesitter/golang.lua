local TreeSitter = require("refactoring.treesitter.treesitter")
local Version = require("refactoring.version")

local Golang = {}

function Golang.new(bufnr, ft)
    return TreeSitter:new({
        version = Version:new(
            TreeSitter.version_flags.Scopes,
            TreeSitter.version_flags.Locals,
            TreeSitter.version_flags.Classes
        ),
        filetype = ft,
        bufnr = bufnr,
        scope_names = {
            function_declaration = "function",
            method_declaration = "function",
        },
        class_names = {
            method_declaration = 0,
        },
    }, bufnr)
end

return Golang
