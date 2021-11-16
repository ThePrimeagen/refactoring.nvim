local Config = require("refactoring.config")
local Query = require("refactoring.query")
local TreeSitter = require("refactoring.treesitter")
local Point = require("refactoring.point")

-- TODO: Move refactor into the actual init function.  Seems weird
-- to have here.  Also make refactor object into a table instead of this
-- monstrosity
local function refactor_setup(bufnr, config)
    config = config or Config.get()
    bufnr = bufnr or vim.fn.bufnr()

    return function()
        local filetype = vim.bo[bufnr].filetype
        local root = Query.get_root(bufnr, filetype)
        local win = vim.api.nvim_get_current_win()

        local refactor = {
            cursor = Point:from_cursor(),
            highlight_start_col = vim.fn.col("'<"),
            code = config:get_code_generation_for(filetype),
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
            config = config,
            buffers = { bufnr },
        }

        return true, refactor
    end
end

return refactor_setup
