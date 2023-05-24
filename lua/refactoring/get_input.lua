local Config = require("refactoring.config")

-- This will be able to be hot swapped out with better input capture as we
-- go on.  This is just a place holder
local async = require("plenary.async")
local input = async.wrap(function(prompt, text, completion, callback)
    vim.ui.input({
        prompt = prompt,
        default = text,
        completion = completion,
    }, callback)
end, 4)

---@param question string
---@param text string|nil
---@return string|nil
local function get_input(question, text)
    text = text or ""

    -- TODO: Extract to class
    local automation_input = Config.get():get_automated_input()
    if automation_input ~= nil then
        return automation_input
    end

    return input(question, text, nil)
end

return get_input
