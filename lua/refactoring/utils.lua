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

---@param inputstr string
---@param sep string
---@return string[]
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

---@return RefactorRegion
function M.get_top_of_file_region()
    local range = { line = 0, character = 0 }
    return Region:from_lsp_range_insert({ start = range, ["end"] = range })
end

-- FROM http://lua-users.org/wiki/CommonFunctions
-- remove trailing and leading whitespace from string.
---@param s string|table<any, string>
---@return string|table<any, string>
function M.trim(s)
    if type(s) == "table" then
        for i, str in pairs(s) do
            s[i] = M.trim(str) --[[@as string]]
        end
        return s
    end
    -- from PiL2 20.4
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

---@param node TSNode
---@param out string[]|nil
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

---@param nodes TSNode[]
---@return TSNode[]
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
---@param node TSNode
---@return RefactorRegion
function M.region_one_line_up_from_node(node)
    local region = Region:from_node(node)
    region.end_row = region.start_row
    region.start_col = 1
    region.end_col = 1
    return region
end

---@param nodes TSNode[]
---@param region RefactorRegion
---@return TSNode[]
M.region_complement = function(nodes, region)
    return vim.tbl_filter(function(node)
        return not region:contains(Region:from_node(node))
    end, nodes)
end

---@param nodes TSNode[]
---@param region RefactorRegion
---@param bufnr integer|nil
---@return TSNode[]
M.region_intersect = function(nodes, region, bufnr)
    return vim.tbl_filter(function(node)
        return region:contains(Region:from_node(node, bufnr))
    end, nodes)
end

---@param nodes TSNode[]
---@param region RefactorRegion
---@return TSNode[]
M.after_region = function(nodes, region)
    return vim.tbl_filter(function(node)
        return Region:from_node(node):is_after(region)
    end, nodes)
end

---@param t table
---@return boolean
function M.table_has_keys(t)
    for _ in pairs(t) do
        return true
    end
    return false
end

-- TODO: Very unsure if this needs to be a "util" or not But this is super
-- useful in refactor 106 and I assume it will be used elsewhere quite a bit
---@param bufnr integer
---@param ... TSNode
---@return table<string, true>
function M.nodes_to_text_set(bufnr, ...)
    local out = {}
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

---@param a table
---@param b table
---@return table
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
---@return RefactorRegion
function M.region_above_node(node)
    local scope_region = Region:from_node(node)

    scope_region.start_row = math.max(scope_region.start_row - 1, 1)
    scope_region.start_col = 1
    scope_region.end_row = scope_region.start_row
    scope_region.end_col = scope_region.start_col

    return scope_region
end

---@param node TSNode|nil
---@return boolean
local function is_comment_or_decorator_node(node)
    if node == nil then
        return false
    end

    local comment_and_decorator_node_types = {
        "comment",
        "block_comment",
        "decorator",
    }

    for _, node_type in ipairs(comment_and_decorator_node_types) do
        if node_type == node:type() then
            return true
        end
    end

    return false
end

---@param node TSNode
---@return TSNode first_node_row, integer start_row
function M.get_first_node_in_row(node)
    local start_row, _, _, _ = node:range()
    local first = node
    while true do
        --- @type TSNode
        local parent = first:parent()
        if parent == nil then
            break
        end
        local parent_row, _, _, _ = parent:range()
        if parent_row ~= start_row then
            break
        end
        first = parent
    end
    return first, start_row
end

-- TODO (TheLeoP): clean this up and use some kind of configuration for each language
---@param refactor Refactor
function M.get_non_comment_region_above_node(refactor)
    local prev_sibling = M.get_first_node_in_row(refactor.scope)
        :prev_named_sibling()
    if is_comment_or_decorator_node(prev_sibling) then
        --- @type integer
        local start_row
        while true do
            -- Only want first value
            start_row = prev_sibling:range()
            local temp = prev_sibling:prev_sibling()
            if is_comment_or_decorator_node(temp) then
                -- Only want first value
                local temp_row = temp:range()
                if start_row - temp_row == 1 then
                    prev_sibling = temp
                else
                    break
                end
            else
                break
            end
        end

        if start_row > 0 then
            return M.region_above_node(prev_sibling)
        else
            return M.region_above_node(refactor.scope)
        end
    else
        return M.region_above_node(refactor.scope)
    end
end

---@param refactor Refactor
---@return string[]
function M.get_selected_locals(refactor)
    local local_defs =
        refactor.ts:get_local_defs(refactor.scope, refactor.region)
    local region_refs =
        refactor.ts:get_region_refs(refactor.scope, refactor.region)

    local_defs = vim.tbl_map(
        ---@param node TSNode
        ---@return TSNode[]
        function(node)
            return M.node_to_parent_if_needed(refactor, node)
        end,
        local_defs
    )
    region_refs = vim.tbl_map(
        ---@param node TSNode
        ---@return TSNode[]
        function(node)
            return M.node_to_parent_if_needed(refactor, node)
        end,
        region_refs
    )

    local bufnr = refactor.buffers[1]
    local local_def_map = M.nodes_to_text_set(bufnr, local_defs)
    local region_refs_map = M.nodes_to_text_set(bufnr, region_refs)
    return M.table_key_intersect(local_def_map, region_refs_map)
end

---@param refactor Refactor
---@param node TSNode
---@return TSNode
function M.node_to_parent_if_needed(refactor, node)
    local parent = node:parent()
    if refactor.ts.should_check_parent_node(parent:type()) then
        return parent
    end
    return node
end

return M
