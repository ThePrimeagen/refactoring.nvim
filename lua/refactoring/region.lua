local Point = require("refactoring.point")

local api = vim.api

---@class refactor.Region
---@field start_row number: The 1-based row
---@field start_col number: The 1-based col
---@field end_row number: The 1-based row
---@field end_col number: The 1-based col
---@field bufnr number: the buffer that the region is from
---@field type "v" | "V" | ""
local Region = {}
Region.__index = Region

--- Get a Region from motion (marks [ and ])
---@param opts {include_end_of_line: boolean, type :"v" | "V" | "" | nil, bufnr: integer} | nil
---@return refactor.Region
function Region:from_motion(opts)
    local type = opts and opts.type or "v"
    local bufnr = opts and opts.bufnr or api.nvim_get_current_buf()

    local start_row = vim.fn.line("'[")
    local start_col = vim.fn.col("'[")
    local end_row = vim.fn.line("']")
    local end_col = type == "V" and vim.v.maxcol or vim.fn.col("']")

    if opts and opts.include_end_of_line then
        local last_line =
            api.nvim_buf_get_lines(0, end_row - 1, end_row, true)[1]
        local line_length = vim.str_utfindex(last_line, #last_line)
        end_col = math.min(end_col, line_length) --[[@as integer]]
    end

    return setmetatable({
        bufnr = bufnr,
        start_row = start_row,
        start_col = start_col,
        end_row = end_row,
        end_col = end_col,
        type = type,
    }, self)
end

---@param bufnr integer
---@param start_row integer
---@param start_col integer
---@param end_row integer
---@param end_col integer
---@param type "v" | "V" | "" | nil
---@return refactor.Region
function Region:from_values(bufnr, start_row, start_col, end_row, end_col, type)
    type = type or "v"
    return setmetatable({
        start_row = start_row,
        start_col = start_col,
        end_row = end_row,
        end_col = end_col,
        bufnr = bufnr,
        type = type,
    }, self)
end

---@param bufnr integer
---@return refactor.Region
function Region:empty(bufnr)
    return setmetatable({
        bufnr = bufnr,
        type = "v",
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
---@return refactor.Region
function Region:from_node(node, bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()
    local start_row, start_col, end_row, end_col = node:range()

    local lines = api.nvim_buf_get_lines(bufnr, 0, -1, true)
    local start_line = lines[start_row + 1]
    start_col = vim.fn.charidx(start_line, start_col)

    -- the parent node may have an end_row #lines + 1
    local end_i = math.min(end_row + 1, #lines)
    local end_line = lines[end_i]
    end_col = vim.fn.charidx(end_line, end_col)

    return setmetatable({
        bufnr = bufnr,
        start_row = start_row + 1,
        start_col = start_col + 1,
        end_row = end_row + 1,
        end_col = end_col,
        type = "v",
    }, self)
end

--- Get a region from a given point.
---@param point refactor.Point the point to use as start- and endpoint
---@param bufnr? number  the bufnr for the region
---@return refactor.Region
function Region:from_point(point, bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()

    return setmetatable({
        bufnr = bufnr,
        start_row = point.row,
        start_col = point.col,
        end_row = point.row,
        end_col = point.col,
        type = "v",
    }, self)
end

---@param lsp_range lsp.Range
---@param bufnr integer|nil
---@return refactor.Region
function Region:from_lsp_range_insert(lsp_range, bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()

    return setmetatable({
        bufnr = bufnr,
        start_row = lsp_range.start.line + 1,
        start_col = lsp_range.start.character + 1,
        end_row = lsp_range["end"].line + 1,
        end_col = lsp_range["end"].character + 1,
        type = "v",
    }, self)
end

---@param lsp_range lsp.Range
---@param bufnr integer|nil
---@return refactor.Region
function Region:from_lsp_range_replace(lsp_range, bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()

    return setmetatable({
        bufnr = bufnr,
        start_row = lsp_range.start.line + 1,
        start_col = lsp_range.start.character + 1,
        end_row = lsp_range["end"].line + 1,
        end_col = lsp_range["end"].character,
        type = "v",
    }, self)
end

---@param root TSNode
---@return TSNode? # the node contained by this region
function Region:to_ts_node(root)
    local s_row, s_col, e_row, e_col = self:to_ts()
    return root:named_descendant_for_range(s_row, s_col, e_row, e_col)
end

--- Convert a region to a treesitter region
---@return integer start_row, integer start_col, integer end_row, integer end_col
function Region:to_ts()
    return self.start_row - 1,
        self.start_col - 1,
        self.end_row - 1,
        self.end_col
end

--- Get the lines contained in the region
---@return string[]
function Region:get_lines()
    local offset = 0
    local text = vim.fn.getregion({
        self.bufnr,
        self.start_row,
        self.start_col,
        offset,
    }, {
        self.bufnr,
        self.end_row,
        self.end_col,
        offset,
    }, { type = "V" })
    return text
end

--- Get the left boundary of the region
---@return refactor.Point
function Region:get_start_point()
    return Point:from_values(self.start_row, self.start_col)
end

--- Get the right boundary of the region
---@return refactor.Point
function Region:get_end_point()
    return Point:from_values(self.end_row, self.end_col)
end

---@return string[]
function Region:get_text()
    local offset = 0
    local text = vim.fn.getregion({
        self.bufnr,
        self.start_row,
        self.start_col,
        offset,
    }, {
        self.bufnr,
        self.end_row,
        self.end_col,
        offset,
    }, { type = self.type })
    return text
end

--- Convert a region to an LSP Range inteded to be used to insert text (start and end should the same despite end being exclusive)
---@return lsp.Range
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

--- Convert a region to an LSP Range intended to be used to replace text (end should be exclusive)
---@return lsp.Range
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

---@class refactor.TextEdit : lsp.TextEdit
---@field bufnr integer?

---@param text string
---@return refactor.TextEdit
function Region:to_lsp_text_edit_insert(text)
    return {
        range = self:to_lsp_range_insert(),
        newText = text,
    }
end

---@param text string
---@return refactor.TextEdit
function Region:to_lsp_text_edit_replace(text)
    return {
        range = self:to_lsp_range_replace(),
        newText = text,
    }
end

---@return refactor.Region
function Region:clone()
    local clone = Region:empty(self.bufnr)

    clone.start_row = self.start_row
    clone.start_col = self.start_col
    clone.end_row = self.end_row
    clone.end_col = self.end_col
    clone.type = self.type

    return clone
end

--- Returns true if self contains region.
---@param region refactor.Region
---@return boolean
function Region:contains(region)
    if region.bufnr ~= self.bufnr then
        return false
    end

    return self:get_start_point():leq(region:get_start_point())
        and self:get_end_point():geq(region:get_end_point())
end

--- Returns true if self is above region
---@param region refactor.Region
---@return boolean
function Region:above(region)
    if region.bufnr ~= self.bufnr then
        return false
    end

    return self:get_start_point():lt(region:get_start_point())
        and self:get_end_point():lt(region:get_start_point())
end

--- Returns true if self contains point.
---@param point refactor.Point
---@return boolean
function Region:contains_point(point)
    return self:get_start_point():leq(point) and self:get_end_point():geq(point)
end

--- Return true if the position of self lies after the position of region
---@param region refactor.Region
---@return boolean
function Region:is_after(region)
    return self:get_start_point():gt(region:get_end_point())
end

return Region
