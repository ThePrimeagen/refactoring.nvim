
local M = {}

function M.from_input(input_idx)
    return function(refactor)
        -- OPTIONS? We should probably configure this
        vim.cmd(":vnew")
        print("Filetype", refactor.filetype)
        vim.cmd(string.format(":set filetype=%s", refactor.filetype))
        vim.cmd(string.format(":w! %s", refactor.input[input_idx]))
        table.insert(refactor.buffers, vim.fn.bufnr())
        return true, refactor
    end
end

return M
