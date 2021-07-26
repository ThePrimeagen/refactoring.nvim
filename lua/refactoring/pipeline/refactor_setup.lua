local utils = require("refactoring.utils")

local function refactor_setup(bufnr, options)
    return function()
        -- lua 1  based index
        -- vim apis are 1 based
        -- treesitter is 0 based
        -- first entry (1), line 1, row 0
        bufnr = bufnr or 0

        local lang = vim.bo.filetype
        local root = utils.get_root(lang)

        return true, {
            bufnr = bufnr,
            root = root,
            lang = lang,
            options = options
        }
    end
end

return refactor_setup
