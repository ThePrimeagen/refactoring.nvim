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

    -- TODO: generalize node type checks for different languages in treesitter
    if
        count == 0
        -- cpp special case
        or node:type() == "string_literal"
        -- go special case
        or node:type() == "interpreted_string_literal"
    then
        local cur_bufnr = vim.api.nvim_get_current_buf()
        local text = vim.treesitter.get_node_text(node, cur_bufnr)
        table.insert(out, text)
        return out
    end

    for child in node:iter_children() do
        M.get_node_text(child, out)
    end

    return out
end

---@param a TSNode
---@param b TSNode
---@return boolean
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
--- @param a TSNode the containing node
--- @param b TSNode the node to be contained
function M.node_contains(a, b)
    if a == nil or b == nil then
        return false
    end

    local _, _, _, a_end_col = a:range()
    local start_row, start_col, end_row, end_col = b:range()

    if end_col == a_end_col then
        end_col = end_col - 1
    end

    return vim.treesitter.is_in_node_range(a, start_row, start_col)
        and vim.treesitter.is_in_node_range(a, end_row, end_col)
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
    local bufnr = vim.api.nvim_get_current_buf()
    for i = 1, select("#", ...) do
        local nodes = select(i, ...)
        for _, node in pairs(nodes) do
            local text = vim.treesitter.get_node_text(node, bufnr)
            if text ~= nil then
                out[text] = true
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

---@param node TSNode
function M.region_above_node(node)
    local scope_region = Region:from_node(node)
    local lsp_range = scope_region:to_lsp_range()
    lsp_range.start.line = math.max(lsp_range.start.line - 1, 0)
    lsp_range.start.character = 0
    lsp_range["end"] = lsp_range.start
    return Region:from_lsp_range(lsp_range)
end

return M
