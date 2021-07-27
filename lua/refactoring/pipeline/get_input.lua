local function get_input(question, text)
    text = text or ""
    return function(refactor)
        local result = vim.fn.input(question, text)
        if not refactor.input then
            refactor.input = {}
        end

        table.insert(refactor.input, result)

        return true, refactor
    end
end

return get_input
