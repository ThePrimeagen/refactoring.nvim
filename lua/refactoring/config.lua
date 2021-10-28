local default_code_generation = require("refactoring.code_generation")

-- There is no formatting that we should do
local default_formatting = {
    lua = {},
    go = {},

    -- Python needs tons of work to become correct.
    python = {},

    default = {
        cmd = [[ :silent norm! mzgg=G`z ]],
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
    return config.formatting[filetype] or config.formatting.default
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

function M.setup()
    -- TODO: TJ fill this in...
end

return M
