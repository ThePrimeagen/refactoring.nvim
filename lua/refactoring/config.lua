local default_formatting = {
    typescript = {
	cmd = [[ :norm! gg=G ]]
    },
    lua = {
        -- cmd = [[ !stylua % ]],
    },
    go = {
        -- cmd = [[ !gofmt -w % ]],
    },
}
local default_code_generation = {
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
    go = {
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
    },
}

local config = {
    code_generation = default_code_generation,
    formatting = default_formatting,
    _automation = {},
}

function config.get_code_generation_for(lang)
    return config.code_generation[lang]
end

function config.get_formatting_for(filetype)
    return config.formatting[filetype]
end

local M = {}

function M.get_code_generation_for(lang)
    return config.get_code_generation_for(lang)
end

function M.get_formatting_for(filetype)
    return config.get_formatting_for(filetype)
end

function M.get_config()
    return config
end

function M.automate_input(inputs)
    if type(inputs) ~= "table" then
        inputs = { inputs }
    end

    -- TODO: This feels wrong.  I feel like config needs to become an object
    -- TODO: Refactor this into a class.
    config._automation.inputs = inputs
    config._automation.inputs_idx = 0
end

function M.setup(config)
    -- TODO: TJ fill this in...
end

return M
