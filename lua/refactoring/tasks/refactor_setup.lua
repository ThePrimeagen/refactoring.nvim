local Query = require("refactoring.query")
local TreeSitter = require("refactoring.treesitter")
local Point = require("refactoring.point")

local function refactor_setup(bufnr, options)
    bufnr = bufnr or vim.fn.bufnr()

    return function()
        local filetype = vim.bo[bufnr].filetype
        local root = Query.get_root(bufnr, filetype)
        local win = vim.api.nvim_get_current_win()

        local refactor = {
            cursor_point = Point:from_cursor(),
            code = options.get_code_generation_for(filetype),
            ts = TreeSitter.get_treesitter(),
            filetype = filetype,
            bufnr = bufnr,
            win = win,
            query = Query:new(
                bufnr,
                filetype,
                vim.treesitter.get_query(filetype, "refactoring")
            ),
            locals = Query:new(
                bufnr,
                filetype,
                vim.treesitter.get_query(filetype, "locals")
            ),
            root = root,
            options = options,
            buffers = { bufnr },
        }

        return true, refactor
    end
end

return refactor_setup
