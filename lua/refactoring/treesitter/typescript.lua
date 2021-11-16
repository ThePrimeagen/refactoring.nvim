local ts_utils = require("nvim-treesitter.ts_utils")
local TreeSitter = require("refactoring.treesitter.treesitter")
local Version = require("refactoring.version")

local Typescript = {}

local BaseFieldNode = {}
BaseFieldNode.__index = BaseFieldNode

local FieldNode = function(fieldname)
    return function(node)
        return setmetatable({
            fieldname = fieldname,
            node = node,
        }, {
            __index = BaseFieldNode,

            __tostring = function(self)
                local name_node = self.node:field(self.fieldname)[1]
                return ts_utils.get_node_text(name_node, 0)[1]
            end,
        })
    end
end

local StringNode = function(text)
    return function()
        return setmetatable({}, {
            __tostring = function()
                return text
            end,
        })
    end
end

function Typescript.new(bufnr, ft)
    return TreeSitter:new({
        version = Version:new(
            TreeSitter.version_flags.Scopes,
            TreeSitter.version_flags.Locals
        ),
        filetype = ft,
        bufnr = bufnr,
        scope_names = {
            program = "program",
            function_declaration = "function",
            method_definition = "function",
            arrow_function = "function",
            class_declaration = "class",
        },
        debug_paths = {
            function_declaration = FieldNode("name"),
            method_definition = FieldNode("name"),
            class_declaration = FieldNode("name"),
            arrow_function = StringNode("(anon)"),
            if_statement = StringNode("if"),
            for_statement = StringNode("for"),
            while_statement = StringNode("while"),
            do_statement = StringNode("do"),
        },
        to_string = function(self, node)
            if true then
                return tostring(node)
            end

            local type = node:type()
            local debug_type = self.debug_paths[type]
            if debug_type == "function" then
                local name_node = node:field("name")[1]

                if name_node then
                    return ts_utils.get_node_text(name_node)[1]
                else
                    if type == "arrow_function" then
                        return "() => {}"
                    end
                    return "function"
                end
            end

            return tostring(self.debug_paths[node:type()]) or "(unknown node)"
        end,
    }, bufnr)
end

return Typescript
