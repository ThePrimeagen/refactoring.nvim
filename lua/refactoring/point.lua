local function getpos()
    return vim.fn.line("."), vim.fn.col(".")
end

---@class Point
---@field row number: The 1-based row
---@field col number: The 1-based col
local Point = {}
Point.__index = Point

--- Get a Point from the current selection
---@return Point
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

--- Convert a point to a vim point (line, col 1 based)
function Point:to_vim()
    return self.row, self.col
end

--- Convert a point to a tree sitter point
function Point:to_ts()
    return self.row - 1, self.col
end

function Point:clone()
    local clone = Point:empty()

    clone.row = self.row
    clone.col = self.col

    return clone
end

return Point
