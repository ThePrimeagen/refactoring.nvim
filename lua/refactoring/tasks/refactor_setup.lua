local Config = require("refactoring.config")
local Query = require("refactoring.query")
local TreeSitter = require("refactoring.treesitter")
local Point = require("refactoring.point")

-- TODO: Move refactor into the actual init function.  Seems weird
-- to have here.  Also make refactor object into a table instead of this
-- monstrosity

---
---@param input_bufnr number
---@param config Config
---@return function
local function refactor_setup(input_bufnr, config)
    input_bufnr = input_bufnr or vim.api.nvim_get_current_buf()
    config = config or Config.get()

    --- @retun boolean, Refactor
    return function()
        -- Setting bufnr to test bufnr
        local bufnr
        if config:get_test_bufnr() ~= nil then
            bufnr = config:get_test_bufnr()
        else
            bufnr = input_bufnr
        end

        local filetype = vim.bo[bufnr].filetype
        -- TODO: Move this to treesitter get root and get rid of Query
        local root = Query.get_root(bufnr, filetype)
        local win = vim.api.nvim_get_current_win()
        local cursor = Point:from_cursor()

        ---@class Refactor
        ---@field region? RefactorRegion
        ---@field region_node? TSNode
        ---@field scope? TSNode
        ---@field cursor_col_adjustment? number
        ---@field text_edits? {add_newline: boolean, region: RefactorRegion, text: string} | LspRange
        ---@field code code_generation
        local refactor = {
            ---@type {cursor: number, highlight_start?: number, highlight_end?: number, func_call?: number}
            whitespace = {
                cursor = vim.fn.indent(cursor.row),
            },
            cursor = cursor,
            highlight_start_col = vim.fn.col("'<"),
            code = config:get_code_generation_for(filetype),
            ts = TreeSitter.get_treesitter(),
            filetype = filetype,
            bufnr = bufnr,
            win = win,
            root = root,
            config = config,
            buffers = { bufnr },
        }

        return true, refactor
    end
end

return refactor_setup
