local TreeSitter = require("refactoring.treesitter.treesitter")
local Version = require("refactoring.version")
local Nodes = require("refactoring.treesitter.nodes")
local FieldNode = Nodes.FieldNode

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
        debug_paths = {
            class_definition = FieldNode("name"),
            function_definition = FieldNode("name"),
        },
    }, bufnr)
end

return Python
