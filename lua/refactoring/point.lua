local function getpos()
    return vim.fn.line("."), vim.fn.col(".")
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

function Point:to_vim_win()
    return self.row, self.col - 1
end

--- Convert a point to a vim point (line, col 1 based)
function Point:to_vim()
    return self.row, self.col
end

--- Convert a point to a tree sitter point
function Point:to_ts()
    return self.row - 1, self.col
end

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

--- TODO add documentation
function Point:compareTo(point)
    if point.row == self.row and point.col == self.col then
        return 0
    end

    if point.row == self.row then
        return point.col < self.col and 1 or -1
    end

    return point.row < self.row and 1 or -1
end

function Point:lt(point)
    return self:compareTo(point) == -1
end

function Point:gt(point)
    return self:compareTo(point) == 1
end

function Point:leq(point)
    return not self:gt(point)
end

function Point:geq(point)
    return not self:lt(point)
end

return Point
