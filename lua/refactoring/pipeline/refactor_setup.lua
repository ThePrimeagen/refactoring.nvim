local utils = require("refactoring.utils")

local function refactor_setup(bufnr, options)
    bufnr = bufnr or vim.fn.bufnr()

    return function()
        local filetype = vim.bo[bufnr].filetype
        local root = utils.get_root(bufnr, filetype)
        local refactor = {
            filetype = filetype,
            bufnr = bufnr,
            root = root,
            options = options,
            buffers = { bufnr },
        }

        return true, refactor
    end
end

return refactor_setup
