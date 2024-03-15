local function getpos()
    local cursor = vim.api.nvim_win_get_cursor(0)
    return cursor[1], cursor[2]
end

---@class RefactorPoint
---@field row number: The 1-based row
---@field col number: The 1-based col
local Point = {}
Point.__index = Point

--- Get a Point from the current selection
---@return RefactorPoint
function Point:from_cursor()
    local row, col = getpos()

    return setmetatable({
        row = row,
        col = col,
    }, self)
end

function Point:from_values(row, col)
    return setmetatable({
        row = row,
        col = col,
    }, self)
end

function Point:empty()
    return setmetatable({}, self)
end

--- Convert a point to a tree sitter point
function Point:to_ts()
    return self.row - 1, self.col
end

---@param root TSNode
function Point:to_ts_node(root)
    local s_row, s_col = self:to_ts()
    return root:descendant_for_range(s_row, s_col, self:to_ts())
end

function Point:clone()
    local clone = Point:empty()

    clone.row = self.row
    clone.col = self.col

    return clone
end

--- Compare the position of two points.
-- Given two points with positions pos_1 and pos_2
-- return -1 if pos_1 < pos_2, 0 if pos_1 == pos_2 and 1 otherwise.
--- @param point RefactorPoint the second point to compare to.
--- @return integer # either -1, 0 or 1
function Point:compare_to(point)
    if self.row ~= point.row then
        return self.row < point.row and -1 or 1
    end

    if self.col ~= point.col then
        return self.col < point.col and -1 or 1
    end

    return 0
end

--- Returns true if position of self < position of point
function Point:lt(point)
    return self:compare_to(point) == -1
end

--- Returns true if position of self > position of point
function Point:gt(point)
    return self:compare_to(point) == 1
end

--- Returns true if position of self <= position of point
function Point:leq(point)
    return not self:gt(point)
end

--- Returns true if position of self >= position of point
function Point:geq(point)
    return not self:lt(point)
end

return Point
