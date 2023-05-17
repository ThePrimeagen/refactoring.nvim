local Point = require("refactoring.point")

---@return integer start_row, integer start_col, integer end_row, integer end_col
local function get_selection_range()
    local start_row = vim.fn.line("'<")
    local start_col = vim.fn.col("'<")
    local end_row = vim.fn.line("'>")
    local end_col = vim.fn.col("'>")

    return start_row, start_col, end_row, end_col
end

---@class RefactorRegion
--- The following fields act similar to a cursor
---@field start_row number: The 1-based row
---@field start_col number: The 1-based col
---@field end_row number: The 1-based row
---@field end_col number: The 1-based col
---@field bufnr number: the buffer that the region is from
local Region = {}
Region.__index = Region

--- Get a Region from the current selection
---@return RefactorRegion
function Region:from_current_selection()
    local start_row, start_col, end_row, end_col = get_selection_range()

    return setmetatable({
        bufnr = vim.api.nvim_get_current_buf(),
        start_row = start_row,
        start_col = start_col,
        end_row = end_row,
        end_col = end_col,
    }, self)
end

---@param bufnr integer
---@param start_row integer
---@param start_col integer
---@param end_row integer
---@param end_col integer
---@return RefactorRegion
function Region:from_values(bufnr, start_row, start_col, end_row, end_col)
    return setmetatable({
        start_row = start_row,
        start_col = start_col,
        end_row = end_row,
        end_col = end_col,
        bufnr = bufnr,
    }, self)
end

---@param bufnr integer
---@return RefactorRegion
function Region:empty(bufnr)
    return setmetatable({
        bufnr = bufnr,
    }, self)
end

---@return boolean
function Region:is_empty()
    if
        self.start_row == 0
        and self.start_col == 0
        and self.end_row == 0
        and self.end_col == 0
    then
        return true
    end
    return false
end

--- Get a region from a Treesitter Node
---@param node TSNode
---@param bufnr? number
---@return RefactorRegion
function Region:from_node(node, bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local start_line, start_col, end_line, end_col = node:range()

    -- TODO: is col correct?
    return setmetatable({
        bufnr = bufnr,
        start_row = start_line + 1,
        start_col = start_col + 1,
        end_row = end_line + 1,
        end_col = end_col,
    }, self)
end

--- Get a region from a given point.
---@param point RefactorPoint the point to use as start- and endpoint
---@param bufnr? number  the bufnr for the region
---@return RefactorRegion
function Region:from_point(point, bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    return setmetatable({
        bufnr = bufnr,
        start_row = point.row,
        start_col = point.col,
        end_row = point.row,
        end_col = point.col,
    }, self)
end

---@param lsp_range LspRange
---@param bufnr integer|nil
---@return RefactorRegion
function Region:from_lsp_range_insert(lsp_range, bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    return setmetatable({
        bufnr = bufnr,
        start_row = lsp_range.start.line + 1,
        start_col = lsp_range.start.character + 1,
        end_row = lsp_range["end"].line + 1,
        end_col = lsp_range["end"].character + 1,
    }, self)
end

---@param lsp_range LspRange
---@param bufnr integer|nil
---@return RefactorRegion
function Region:from_lsp_range_replace(lsp_range, bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    return setmetatable({
        bufnr = bufnr,
        start_row = lsp_range.start.line + 1,
        start_col = lsp_range.start.character + 1,
        end_row = lsp_range["end"].line + 1,
        end_col = lsp_range["end"].character,
    }, self)
end

---@param root TSNode
---@return TSNode # the node contained by this region
function Region:to_ts_node(root)
    local s_row, s_col, e_row, e_col = self:to_ts()
    return root:named_descendant_for_range(s_row, s_col, e_row, e_col)
end

--- Convert a region to a tree sitter region
function Region:to_ts()
    -- Need the -2 for end_col to be  correct for `ts_utils.is_in_node_range`
    -- function results when checking scope for languages like python
    return self.start_row - 1,
        self.start_col - 1,
        self.end_row - 1,
        -- TODO (TheLeoP): fix: it's possible to wrongly select a node with a shorter range (example: select "foo" instead of "foo()" in golang)
        self.end_col - 2
end

--- Get the lines contained in the region
function Region:get_lines()
    local text = vim.api.nvim_buf_get_lines(
        self.bufnr,
        self.start_row - 1,
        self.end_row,
        false
    )
    return text
end

--- Get the left boundary of the region
function Region:get_start_point()
    return Point:from_values(self.start_row, self.start_col)
end

--- Get the right boundary of the region
function Region:get_end_point()
    return Point:from_values(self.end_row, self.end_col)
end

function Region:get_text()
    local text = vim.api.nvim_buf_get_lines(
        self.bufnr,
        self.start_row - 1,
        self.end_row,
        false
    )

    local text_length = #text
    local end_col = math.min(#text[text_length], self.end_col)
    local end_idx = vim.str_byteindex(text[text_length], end_col)
    local start_idx = vim.str_byteindex(text[1], self.start_col)

    text[text_length] = text[text_length]:sub(1, end_idx)
    text[1] = text[1]:sub(start_idx)

    return text
end

---@class LspPoint
---@field line number
---@field character number

---@class LspRange
---@field start LspPoint
---@field end LspPoint

--- Convert a region to an LSP Range
---@return LspRange
function Region:to_lsp_range_insert()
    return {
        ["start"] = {
            line = self.start_row - 1,
            character = self.start_col - 1,
        },
        ["end"] = {
            line = self.end_row - 1,
            character = self.end_col - 1,
        },
    }
end

--- Convert a region to an LSP Range
---@return LspRange
function Region:to_lsp_range_replace()
    return {
        ["start"] = {
            line = self.start_row - 1,
            character = self.start_col - 1,
        },
        ["end"] = {
            line = self.end_row - 1,
            character = self.end_col,
        },
    }
end

---@class LspTextEdit
---@field range LspRange
---@field newText string

---@param text string
---@return LspTextEdit
function Region:to_lsp_text_edit_insert(text)
    return {
        range = self:to_lsp_range_insert(),
        newText = text,
    }
end

---@param text string
---@return LspTextEdit
function Region:to_lsp_text_edit_replace(text)
    return {
        range = self:to_lsp_range_replace(),
        newText = text,
    }
end

---@return RefactorRegion
function Region:clone()
    local clone = Region:empty(self.bufnr)

    clone.start_row = self.start_row
    clone.start_col = self.start_col
    clone.end_row = self.end_row
    clone.end_col = self.end_col

    return clone
end

--- Returns true if self contains region.
---@param region RefactorRegion
function Region:contains(region)
    if region.bufnr ~= self.bufnr then
        return false
    end

    return self:get_start_point():leq(region:get_start_point())
        and self:get_end_point():geq(region:get_end_point())
end

--- Returns true if self contains point.
---@param point RefactorPoint
function Region:contains_point(point)
    return self:get_start_point():leq(point) and self:get_end_point():geq(point)
end

--- Return true if the position of self lies after the position of region
---@param region RefactorRegion
function Region:is_after(region)
    return self:get_start_point():gt(region:get_end_point())
end

return Region
