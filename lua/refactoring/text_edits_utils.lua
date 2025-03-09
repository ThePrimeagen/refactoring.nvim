local code = require("refactoring.code_generation")
local Region = require("refactoring.region")

local M = {}

local MAX_COL = vim.v.maxcol

---@param point_or_region refactor.Region|refactor.Point
---@return refactor.Region
local function to_region(point_or_region)
    if not point_or_region.end_row then
        return Region:from_point(point_or_region --[[@as refactor.Point]])
    end
    return point_or_region --[[@as refactor.Region]]
end

---@param region refactor.Region
---@return refactor.TextEdit
function M.delete_text(region)
    return region:to_lsp_text_edit_replace("")
end

---@param point_or_region refactor.Region|refactor.Point
---@param text string
---@param opts {below: boolean, _end: boolean}|nil
---@return refactor.TextEdit
function M.insert_new_line_text(point_or_region, text, opts)
    opts = opts or {
        below = true,
        _end = true,
    }

    local region = to_region(point_or_region)

    if opts.below then
        text = code.new_line() .. text
    else
        text = text .. code.new_line()
    end

    if opts._end then
        region.start_col = MAX_COL
        region.end_col = MAX_COL
    else
        region.start_col = 1
        region.end_col = 1
    end
    return region:to_lsp_text_edit_insert(text)
end

---@param point_or_region refactor.Region|refactor.Point
---@param text string
---@return refactor.TextEdit
function M.insert_text(point_or_region, text)
    local region = to_region(point_or_region)
    local clone = region:clone()
    clone.end_col = clone.start_col
    clone.end_row = clone.start_row

    return clone:to_lsp_text_edit_insert(text)
end

---@param region refactor.Region
---@param text string
---@return refactor.TextEdit
function M.replace_text(region, text)
    local clone = region:clone()

    return clone:to_lsp_text_edit_replace(text)
end

return M
