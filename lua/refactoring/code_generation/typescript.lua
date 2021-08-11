local typescript = {
    create_constant = function(opts)
        return string.format("const %s = %s;\n", opts.name, opts.value)
    end,
    extract_function = function(opts)
        return {
            create = string.format(
                [[
function %s(%s) {
    %s
    return %s
}

]],
                opts.name,
                table.concat(opts.args, ", "),
                type(opts.body) == "table"
                        and table.concat(opts.body, "\n")
                    or opts.body,
                opts.ret
            ),
            -- TODO: OBVI THIS NEEDS TO BE DIFFERENT...
            call = string.format(
                "const %s = %s(%s)",
                opts.ret,
                opts.name,
                table.concat(opts.args, ", ")
            ),
        }
    end,
}
--[[
local typescript = {
    constant = function(opts)
        return string.format("const %s = %s;\n", opts.name, opts.value)
    end,

    ["return"] = function(opts)
        return string.format("return %s", opts.ret)
    end,

    ["function"] = function(opts)
        return string.format(
            [[
function %s(%s) {
    %s
}
            ]]
--[[,
            opts.name,
            table.concat(opts.args, ", "),
            type(opts.body) == "table"
                    and table.concat(opts.body, "\n")
                or opts.body
        )
    end,

    call_function = function(opts)
        return string.format(
            "%s(%s)",
            opts.name,
            table.concat(opts.args, ", ")
        )
    end,
}

--]]
return typescript
