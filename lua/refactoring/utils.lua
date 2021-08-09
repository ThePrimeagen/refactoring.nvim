local ts_utils = require("nvim-treesitter.ts_utils")
local Region = require("refactoring.region")

local M = {}

function M.get_top_of_file_region()
    local range = { line = 0, character = 0 }
    return Region:from_lsp_range({ start = range, ["end"] = range })
end

-- FROM http://lua-users.org/wiki/CommonFunctions
-- remove trailing and leading whitespace from string.
function M.trim(s)
    if type(s) == "table" then
        for i, str in pairs(s) do
            s[i] = M.trim(str)
        end
        return s
    end
    -- from PiL2 20.4
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- determines if a contains node b.
-- @param a the containing node
-- @param b the node to be contained
function M.node_contains(a, b)
    if a == nil or b == nil then
        return false
    end

    local start_row, start_col, end_row, end_col = b:range()
    return ts_utils.is_in_node_range(a, start_row, start_col)
        and ts_utils.is_in_node_range(a, end_row, end_col)
end

-- determines if a node exists within a range.  Imagine a range selection
-- across '<,'> (a start,end row/column)and an identifier.
-- Does the identifier exist within the selection?
-- @param node the node to be contained
-- @param start_row the start row of the range
-- @param start_col the start column of the range
-- @param end_row the end row of the range
-- @param end_col the end column of the range
M.range_contains_node = function(node, start_row, start_col, end_row, end_col)
    local node_start_row, node_start_col, node_end_row, node_end_col =
        node:range()

    -- There are five possible conditions
    -- 1. node start/end row are contained exclusively within the range.
    -- 2. The range is a single line range
    --   - the node start/end row must equal start_row and cols have to exist
    --     within range, inclusive
    -- 3. The node exists solely within the first line
    --   - node_start_col has to be inclusive with start_col, end col doesn't
    --     matter.
    -- 4. The node exists solely within the last line
    --   - node_start_col doesn't matter whereas node_end_col has to be
    --     inclusive with end_col
    -- 5. The node starts / ends on the same rows and has to have each column
    --    considered
    if start_row < node_start_row and end_row > node_end_row then
        return true
    elseif start_row == end_row then
        return start_row == node_start_row
            and end_row == node_end_row
            and start_col <= node_start_col
            and end_col >= node_end_col
    elseif start_row == node_start_row and start_row == node_end_row then
        return start_col <= node_start_col
    elseif end_row == node_start_row and end_row == node_end_row then
        return end_col >= node_end_col
    elseif start_row <= node_start_row and end_row >= node_end_row then
        return start_col <= node_start_col and end_col >= node_end_col
    end

    return false
end

M.filter_to_selection = function(nodes, region)
    return vim.tbl_filter(function(node)
        return not M.range_contains_node(node, region:to_ts())
    end, nodes)
end

-- TODO: Very unsure if this needs to be a "util" or not But this is super
-- useful in refactor 106 and I assume it will be used elsewhere quite a bit
function M.node_text_to_set(...)
    local out = {}
    for i = 1, select("#", ...) do
        local nodes = select(i, ...)
        for _, node in pairs(nodes) do
            out[ts_utils.get_node_text(node)[1]] = true
        end
    end
    return out
end

function M.region_above_node(node)
    local scope_region = Region:from_node(node)
    local lsp_range = scope_region:to_lsp_range()
    lsp_range.start.line = math.max(lsp_range.start.line - 1, 0)
    lsp_range["end"] = lsp_range.start
    return Region:from_lsp_range(lsp_range)
end

return M
