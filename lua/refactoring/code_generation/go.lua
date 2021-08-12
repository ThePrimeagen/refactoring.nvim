    local go = {
        extract_function = function(opts)
            return {
                create = string.format(
                    [[
func %s(%s) {
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
                call = string.format(
                    "%s := %s(%s)",
                    opts.ret,
                    opts.name,
                    table.concat(opts.args, ", ")
                ),
            }
        end,
    }
    return go

