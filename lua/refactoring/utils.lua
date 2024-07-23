local Region = require("refactoring.region")
local async = require("plenary.async")

local M = {}

function M.wait_frame()
    async.util.scheduler()
end

---@return RefactorRegion
function M.get_top_of_file_region()
    local range = { line = 0, character = 0 }
    return Region:from_lsp_range_insert({ start = range, ["end"] = range })
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

---@param node TSNode
---@param region RefactorRegion
---@return boolean
M.region_complement = function(node, region)
    return not region:contains(Region:from_node(node))
end

---@param node TSNode[]
---@param region RefactorRegion
---@param bufnr integer|nil
---@return boolean
M.region_intersect = function(node, region, bufnr)
    return region:contains(Region:from_node(node, bufnr))
end

---@param node TSNode[]
---@param region RefactorRegion
---@return boolean
M.after_region = function(node, region)
    return Region:from_node(node):is_after(region)
end

---@param bufnr integer
---@param ... TSNode
---@return table<string, true>
function M.nodes_to_text_set(bufnr, ...)
    local out = {} ---@type table<string, true>
    for i = 1, select("#", ...) do
        local nodes = select(i, ...) ---@type TSNode[]
        for _, node in pairs(nodes) do
            local text = vim.treesitter.get_node_text(node, bufnr)
            if text ~= nil then
                out[text] = true
            end
        end
    end
    return out
end

---@param a table<any, any>
---@param b table<any, any>
---@return table
function M.table_key_intersect(a, b)
    local out = {} ---@type table<any, any>
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

    local node_for_region =
        assert(node:named_descendant_for_range(scope_region:to_ts()))

    local import_nodes = {
        "import_statement",
    }

    for _, import_node in ipairs(import_nodes) do
        if node_for_region:type() == import_node then
            scope_region = M.region_above_node(
                assert(node_for_region:next_named_sibling())
            )
        end
    end

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
        ---@cast prev_sibling TSNode
        ---@type integer
        local start_row
        while true do
            -- Only want first value
            start_row = prev_sibling:range()
            local temp = prev_sibling:prev_sibling()
            if is_comment_or_decorator_node(temp) then
                ---@cast temp TSNode
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
            return M.region_above_node(assert(prev_sibling))
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
    local local_defs = vim.iter(
        refactor.ts:get_local_defs(refactor.scope, refactor.region)
    )
        :map(
            ---@param node TSNode
            ---@return TSNode[]
            function(node)
                return M.node_to_parent_if_needed(refactor, node)
            end
        )
        :totable()
    local region_refs = vim.iter(
        refactor.ts:get_region_refs(refactor.scope, refactor.region)
    )
        :map(
            ---@param node TSNode
            ---@return TSNode[]
            function(node)
                return M.node_to_parent_if_needed(refactor, node)
            end
        )
        :totable()

    local bufnr = refactor.buffers[1]
    local local_def_map = M.nodes_to_text_set(bufnr, local_defs)
    local region_refs_map = M.nodes_to_text_set(bufnr, region_refs)
    return M.table_key_intersect(local_def_map, region_refs_map)
end

---@param refactor Refactor
---@param node TSNode
---@return TSNode
function M.node_to_parent_if_needed(refactor, node)
    local parent = assert(node:parent())
    if refactor.ts.should_check_parent_node(parent:type()) then
        return parent
    end
    return node
end

function M.is_visual_mode()
    local mode = vim.api.nvim_get_mode().mode
    -- '\22' is an escaped `<C-v>`
    return mode == "v" or mode == "V" or mode == "\22", mode
end

function M.exit_to_normal_mode()
    -- Don't use `<C-\><C-n>` in command-line window as they close it
    if vim.fn.getcmdwintype() ~= "" then
        local is_vis, cur_mode = M.is_visual_mode()
        if is_vis then
            vim.cmd("normal! " .. cur_mode)
        end
    else
        -- '\28\14' is an escaped version of `<C-\><C-n>`
        vim.cmd("normal! \28\14")
    end
end

return M
