local utils = require("refactoring.utils")

local function refactor_setup(bufnr)
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
        }
    end
end

return refactor_setup
