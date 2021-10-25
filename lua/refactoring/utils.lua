local ts_utils = require("nvim-treesitter.ts_utils")
local Region = require("refactoring.region")

local M = {}

function M.take_one(table, fn)
    if not table then
        return nil
    end

    fn = fn or function()
        return true
    end

    local out = nil
    for k, v in pairs(table) do
        if fn(k, v) then
            out = v
            break
        end
    end

    return out
end

function M.split_string(inputstr, sep)
    local t = {}
    -- [[ lets not think about the edge case there... --]]
    while #inputstr > 0 do
        local start, stop = inputstr:find(sep)
        local str
        if not start then
            str = inputstr
            inputstr = ""
        else
            str = inputstr:sub(1, start - 1)
            inputstr = inputstr:sub(stop + 1)
        end
        table.insert(t, str)
    end
    return t
end

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

function M.get_node_text(node, out)
    out = out or {}
    local count = node:child_count()

    if count == 0 then
        table.insert(out, ts_utils.get_node_text(node)[1])
        return out
    end

    for idx = 0, count - 1 do
        M.get_node_text(node:child(idx), out)
    end

    return out
end

function M.appears_before(a, b)
    local a_row, a_col, a_bytes = a:start()
    local b_row, b_col, b_bytes = b:start()
    if a_row ~= b_row then
        return a_row < b_row
    end

    -- A starts before B
    -- B ends after A
    return (a_col < b_col or b_col + b_bytes > a_col + a_bytes)
end

function M.sort_in_appearance_order(nodes)
    table.sort(nodes, M.appears_before)
    return nodes
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

-- TODO: This likely doesn't work with multistatement line inserts
function M.region_one_line_up_from_node(node)
    local region = Region:from_node(node)
    region.end_row = region.start_row
    region.start_col = 1
    region.end_col = 1
    return region
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

M.region_complement = function(nodes, region)
    return vim.tbl_filter(function(node)
        return not region:contains(Region:from_node(node))
    end, nodes)
end

M.region_intersect = function(nodes, region)
    return vim.tbl_filter(function(node)
        return region:contains(Region:from_node(node))
    end, nodes)
end

-- TODO: Very unsure if this needs to be a "util" or not But this is super
-- useful in refactor 106 and I assume it will be used elsewhere quite a bit
function M.node_text_to_set(...)
    local out = {}
    for i = 1, select("#", ...) do
        local nodes = select(i, ...)
        for _, node in pairs(nodes) do
            local text = ts_utils.get_node_text(node)
            if text and text[1] ~= nil then
                out[text[1]] = true
            end
        end
    end
    return out
end

function M.table_key_intersect(a, b)
    local out = {}
    for k, v in pairs(b) do
        if a[k] then
            out[k] = v
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
