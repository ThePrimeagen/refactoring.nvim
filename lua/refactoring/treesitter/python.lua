local TreeSitter = require("refactoring.treesitter.treesitter")
local Version = require("refactoring.version")

local Python = {}

function Python.new(bufnr, ft)
    return TreeSitter:new({
        version = Version:new(
            TreeSitter.version_flags.Scopes,
            TreeSitter.version_flags.Locals,
            TreeSitter.version_flags.Classes
        ),
        filetype = ft,
        bufnr = bufnr,
        scope_names = {
            function_definition = "function",
            module = "function",
        },
        class_names = {
            class_definition = 0,
        },
    }, bufnr)
end

return Python
