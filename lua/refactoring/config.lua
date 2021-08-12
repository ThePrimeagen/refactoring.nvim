local default_code_generation = require("refactoring.code_generation")

local default_formatting = {
    typescript = {
        cmd = [[ :norm! gg=G ]],
    },
    lua = {
        -- cmd = [[ !stylua % ]],
    },
    go = {
        -- cmd = [[ !gofmt -w % ]],
    },
    python = {
        -- TODO: add python formatting command
    },
}

local config = {
    code_generation = default_code_generation,
    formatting = default_formatting,
    _automation = {},
}
--
-- TODO: remove duplicate config
local ConfigClass = {}
ConfigClass.__index = ConfigClass

function ConfigClass:new()
    return setmetatable({
        code_generation = default_code_generation,
        formatting = default_formatting,
        automation = {
            inputs = {},
            current_input_idx = 0,
        },
    }, self)
end

function ConfigClass:automate_input(inputs)
    if type(inputs) ~= "table" then
        inputs = { inputs }
    end
    self.automation.inputs = inputs
    self.automation.current_input_idx = self.current_input_idx + 1
end

function ConfigClass:get_formatting_for(lang)
    return self.formatting[lang]
end

function ConfigClass:get_code_generation_for(lang)
    return self.code_generation[lang]
end

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

function M.setup()
    -- TODO: TJ fill this in...
    return ConfigClass:new()
end

return M
