local M = {}

local Config = require("refactoring.config")
local async = require("plenary.async")

---@type fun(items: unknown[], prompt?: string, format?: function, kind?: string) : unknown?, integer?
local select = async.wrap(function(items, prompt, format, kind, callback)
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
---@return integer?
function M.select(items, question, format)
    -- TODO: Extract to class
    local automation_input = Config.get():get_automated_input()
    if automation_input ~= nil then
        local automation_input_number = tonumber(automation_input) --[[@as integer]]
        return items[automation_input_number], automation_input_number
    end

    return select(items, question, format, "refactoring.nvim")
end

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
function M.input(question, text)
    text = text or ""

    -- TODO: Extract to class
    local automation_input = Config.get():get_automated_input()
    if automation_input ~= nil then
        return automation_input
    end

    return input(question, text, nil)
end

return M
