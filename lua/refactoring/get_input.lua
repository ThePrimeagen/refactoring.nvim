-- This will be able to be hot swapped out with better input capture as we
-- go on.  This is just a place holder
local function get_input(question, text, options)
    text = text or ""

    local next_input = options.get_next_input()
    if next_input == nil then
        next_input = vim.fn.input(question, text)
    end

    return next_input
end

return get_input
