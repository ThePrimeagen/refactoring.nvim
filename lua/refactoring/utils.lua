local ts_utils = require("nvim-treesitter.ts_utils")
local Region = require("refactoring.region")
local async = require("plenary.async")

local M = {}

-- TODO: Make this work.  I have vim.schedules in the code, though they
-- shouldn't need to be there.  When I use this all my results are before LSP
-- comes back and does something to the code.
function M.wait_frame()
    async.util.scheduler()
end

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

M.after_region = function(nodes, region)
    return vim.tbl_filter(function(node)
        return Region:from_node(node):is_after(region)
    end, nodes)
end

function M.table_has_keys(t)
    for _ in pairs(t) do
        return true
    end
    return false
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
