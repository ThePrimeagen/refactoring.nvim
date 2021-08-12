local typescript = require("refactoring.code_generation.typescript")
local lua = require("refactoring.code_generation.lua")
local go = require("refactoring.code_generation.go")
local python = require("refactoring.code_generation.python")

local M = {
    typescript = typescript,
    lua = lua,
    go = go,
    python = python,
}

return M

--[[
local default_code_generation = {
    lua = {
        extract_function = function(opts)
            return {
                create = string.format(
                    [[
local function %s(%s)
    %s
    return %s
end

]]
--[[,
                    opts.name,
                    table.concat(opts.args, ", "),
                    type(opts.body) == "table"
                            and table.concat(opts.body, "\n")
                        or opts.body,
                    opts.ret
                ),

                call = string.format(
                    "local %s = %s(%s)",
                    opts.ret,
                    opts.name,
                    table.concat(opts.args, ", ")
                ),
            }
        end,
    },
    go = {
        extract_function = function(opts)
            return {
                create = string.format(
                    [[
func %s(%s) {
    %s
    return %s
}
]]
--[[,

                    opts.name,
                    table.concat(opts.args, ", "),
                    type(opts.body) == "table"
                            and table.concat(opts.body, "\n")
                        or opts.body,
                    opts.ret
                ),
                call = string.format(
                    "%s := %s(%s)",
                    opts.ret,
                    opts.name,
                    table.concat(opts.args, ", ")
                ),
            }
        end,
    },
    python = {
        extract_function = function(opts)
            return {
                create = string.format(
                    [[
def %s(%s):
    %s
    return %s


]]
--[[,
                    opts.name,
                    table.concat(opts.args, ", "),
                    type(opts.body) == "table"
                            and table.concat(opts.body, "\n")
                        or opts.body,
                    opts.ret
                ),
                call = string.format(
                    "%s = %s(%s)",
                    opts.ret,
                    opts.name,
                    table.concat(opts.args, ", ")
                ),
            }
        end,
    },
}

]]
