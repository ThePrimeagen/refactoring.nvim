local code = require("refactoring.code_generation")
local Region = require("refactoring.region")

local M = {}

local MAX_COL = 10000

---@param pointOrRegion RefactorRegion|RefactorPoint
---@return RefactorRegion
local function to_region(pointOrRegion)
    if not pointOrRegion.end_row then
        return Region:from_point(pointOrRegion --[[@as RefactorPoint]])
    end
    return pointOrRegion --[[@as RefactorRegion]]
end

---@param region RefactorRegion
---@return RefactorTextEdit
function M.delete_text(region)
    return region:to_lsp_text_edit_replace("")
end

---@param pointOrRegion RefactorRegion|RefactorPoint
---@param text string
---@param opts {below: boolean, _end: boolean}|nil
---@return RefactorTextEdit
function M.insert_new_line_text(pointOrRegion, text, opts)
    opts = opts or {
        below = true,
        _end = true,
    }

    local region = to_region(pointOrRegion)

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

---@param pointOrRegion RefactorRegion|RefactorPoint
---@param text string
---@return RefactorTextEdit
function M.insert_text(pointOrRegion, text)
    local region = to_region(pointOrRegion)
    local clone = region:clone()
    clone.end_col = clone.start_col
    clone.end_row = clone.start_row

    return clone:to_lsp_text_edit_insert(text)
end

---@param region RefactorRegion
---@param text string
---@return RefactorTextEdit
function M.replace_text(region, text)
    local clone = region:clone()

    return clone:to_lsp_text_edit_replace(text)
end

return M
