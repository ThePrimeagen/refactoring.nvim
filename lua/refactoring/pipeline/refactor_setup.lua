local utils = require("refactoring.utils")

local function refactor_setup(bufnr, options)
    bufnr = bufnr or vim.fn.bufnr()

    return function()
        local lang = vim.bo.filetype
        local root = utils.get_root(lang)
        return true, {
            filetype = vim.bo[bufnr].filetype,
            bufnr = bufnr,
            root = root,
            lang = lang,
            options = options,
            buffers = {bufnr}
        }
    end
end

return refactor_setup
