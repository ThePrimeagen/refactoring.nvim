local function get_input(question)
    return function(refactor)
        local result = vim.fn.input(question)
        if not refactor.input then
            refactor.input = {}
        end

        table.insert(refactor.input, result)

        return true, refactor
    end
end

return get_input
