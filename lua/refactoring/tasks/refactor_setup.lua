local Config = require("refactoring.config")
local TreeSitter = require("refactoring.treesitter")
local Point = require("refactoring.point")

-- TODO: Move refactor into the actual init function.  Seems weird
-- to have here.  Also make refactor object into a table instead of this
-- monstrosity

---@param input_bufnr integer
---@param config Config
---@return fun(): true, Refactor
local function refactor_setup(input_bufnr, config)
    input_bufnr = input_bufnr or vim.api.nvim_get_current_buf()
    config = config or Config.get()

    return function()
        --- @type integer
        local bufnr
        if config:get_test_bufnr() ~= nil then
            bufnr = config:get_test_bufnr()
        else
            bufnr = input_bufnr
        end

        local ts = TreeSitter.get_treesitter()

        local filetype = vim.bo[bufnr].filetype --[[@as ft]]
        local root = ts:get_root()
        local win = vim.api.nvim_get_current_win()
        local cursor = Point:from_cursor()

        ---@class Refactor
        ---@field region? RefactorRegion
        ---@field region_node? TSNode
        ---@field identifier_node? TSNode
        ---@field scope? TSNode
        ---@field cursor_col_adjustment? integer
        ---@field text_edits? RefactorTextEdit[] | {bufnr?: integer}[]
        ---@field code code_generation
        ---@field return_value string used by debug.get_path
        ---@field success_message? string
        local refactor = {
            ---@type {cursor: integer, func_call: integer|nil}
            whitespace = {
                cursor = assert(vim.fn.indent(cursor.row)),
            },
            cursor = cursor,
            code = config:get_code_generation_for(filetype),
            ts = ts,
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
