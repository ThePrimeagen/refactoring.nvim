local utils = require("refactoring.utils")
local Region = require("refactoring.region")

local function extract_setup(bufnr)
    return function()
        -- lua 1  based index
        -- vim apis are 1 based
        -- treesitter is 0 based
        -- first entry (1), line 1, row 0
        bufnr = bufnr or 0

        local lang = vim.bo.filetype
        local region = Region:from_current_selection()
        local root = utils.get_root(lang)
        local scope = utils.get_scope_over_selection(root, region, lang)

        return true, {
            bufnr = bufnr,
            lang = lang,
            region = region,
            root = root,
            scope = scope,
        }
    end
end

return extract_setup
