local Config = require("refactoring.config")

-- This will be able to be hot swapped out with better input capture as we
-- go on.  This is just a place holder
local async = require("plenary.async")
-- local input = vim.fn.input
local input = async.wrap(function(prompt, text, completion, callback)
    vim.ui.input({
        prompt = prompt,
        default = text,
        completion = completion,
    }, callback)
end, 4)
local function get_input(question, text)
    text = text or ""

    -- TODO: Extract to class
    local a = Config.get_config()._automation
    if a.inputs then
        local inputs = a.inputs
        if #inputs > a.inputs_idx then
            a.inputs_idx = a.inputs_idx + 1
            return a.inputs[a.inputs_idx]
        end
    end

    return input(question, text, nil)
end

return get_input
