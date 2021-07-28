local config = {
    formatting = {
        typescript = {
            cmd = [[ :norm! gg=G ]],
        },
        lua = {
            -- cmd = [[ !stylua % ]],
        },
    },
    code_generation = {
        typescript = {
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
        },
        lua = {
            extract_function = function(opts)
                return {
                    create = string.format(
                        [[
local function %s(%s)
    %s
    return %s
end
                ]],
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
    },
}

local M = {}

function M.get_config()
    return config
end

function M.setup(config)
    -- TODO: TJ fill this in...
end

return M
