-- This will be able to be hot swapped out with better input capture as we
-- go on.  This is just a place holder
local function get_input(question, text)
    text = text or ""
    return vim.fn.input(question, text)
end

return get_input
