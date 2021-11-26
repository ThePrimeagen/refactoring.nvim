local TreeSitter = require("refactoring.treesitter.treesitter")
local Version = require("refactoring.version")

local Nodes = require("refactoring.treesitter.nodes")
local FieldNode = Nodes.FieldNode
local StringNode = Nodes.StringNode
local QueryNode = Nodes.QueryNode

local Lua = {}

function Lua.new(bufnr, ft)
    return TreeSitter:new({
        version = Version:new(
            TreeSitter.version_flags.Scopes,
            TreeSitter.version_flags.Locals
        ),
        filetype = ft,
        bufnr = bufnr,
        scope_names = {
            program = "program",
            local_function = "function",
            ["function"] = "function",
            function_definition = "function",
        },

        debug_paths = {
            class_specifier = FieldNode("name"),
            function_definition = StringNode("function"),
            ["function"] = QueryNode("(function (function_name) @name)"),
            ["local_function"] = QueryNode(
                "(local_function (identifier) @name)"
            ),
            if_statement = StringNode("if"),
            repeat_statement = StringNode("repeat"),
            for_in_statement = StringNode("for"),
            for_statement = StringNode("for"),
            while_statement = StringNode("while"),
        },
    }, bufnr)
end

return Lua
