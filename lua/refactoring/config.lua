local M = {}

local Config = {}
Config.__index = Config

local default_formatting = {
    typescript = { cmd = [[ :norm! gg=G ]] },
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
            }
        end,
    },
}

-- TODO: add a way to accept other formatting / code_gen opts
function Config:new()
    local conf = {}
    local automation = {}
    automation.current_input_index = 0
    automation.inputs = {}
    conf._automation = automation
    conf.formatting = default_formatting
    conf.code_generation = default_code_generation
    setmetatable(conf, Config)
    return conf
end

function Config:automate_input(inputs)
    if type(inputs) ~= "table" then
        inputs = { inputs }
    end
    self._automation.current_input_index = 0
    self._automation.inputs = inputs
end

function Config:get_code_generation_for(lang)
    return self.code_generation[lang]
end

function Config:get_formatting_for(filetype)
    return self.formatting[filetype]
end

function Config:get_next_input()
    self._automation.current_input_index = self._automation.current_input_index
        + 1
    return self._automation.inputs[self._automation.current_input_index]
end

function M.setup()
    return Config:new()
end

return M
