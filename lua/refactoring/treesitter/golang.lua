local TreeSitter = require("refactoring.treesitter.treesitter")
local Version = require("refactoring.version")
local Nodes = require("refactoring.treesitter.nodes")
local FieldNode = Nodes.FieldNode

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
        block_scope = {
            block = true,
        },
        variable_scope = {
            short_var_declaration = true,
        },
        scope_names = {
            function_declaration = "function",
            method_declaration = "function",
        },
        class_names = {
            method_declaration = 0,
        },
        debug_paths = {
            function_declaration = FieldNode("name"),
            method_declaration = FieldNode("name"),
        },
    }, bufnr)
end

return Golang
