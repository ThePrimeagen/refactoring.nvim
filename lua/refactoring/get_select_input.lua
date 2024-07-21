local Config = require("refactoring.config")

local async = require("plenary.async")

---@type fun(items: unknown[], prompt?: string, format?: function, kind?: string) : unknown?, integer?
local select_input = async.wrap(function(items, prompt, format, kind, callback)
    vim.ui.select(items, {
        prompt = prompt,
        format_item = format,
        kind = kind,
    }, callback)
end, 5)

---@param items unknown[]
---@param question string
---@param format? fun(item: unknown) : string
---@return unknown?
---@return integer
local function get_select_input(items, question, format)
    -- TODO: Extract to class
    local automation_input = Config.get():get_automated_input()
    if automation_input ~= nil then
        local automation_input_number = tonumber(automation_input)
        return items[automation_input_number], automation_input_number
    end

    return select_input(items, question, format, nil)
end

return get_select_input
