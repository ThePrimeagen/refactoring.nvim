local TreeSitter = require("refactoring.treesitter.treesitter")
local Version = require("refactoring.version")
local Nodes = require("refactoring.treesitter.nodes")
local FieldNode = Nodes.FieldNode
local StringNode = Nodes.StringNode

local Cpp = {}

function Cpp.new(bufnr, ft)
    return TreeSitter:new({
        version = Version:new(0),
        filetype = ft,
        bufnr = bufnr,
        debug_paths = {
            class_specifier = FieldNode("name"),
            function_definition = FieldNode(
                "declarator",
                "declarator",
                "declarator"
            ),
            if_statement = StringNode("if"),
            for_statement = StringNode("for"),
            while_statement = StringNode("while"),
            do_statement = StringNode("do"),
        },
    }, bufnr)
end

return Cpp
