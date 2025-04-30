local M = {}

local ts = vim.treesitter
local iter = vim.iter
local api = vim.api

---@param refactor refactor.Refactor
---@param point refactor.Point
function M.get_debug_path(refactor, point)
    local node = assert(ts.get_node({
        bufnr = refactor.bufnr,
        pos = { point.row - 1, point.col },
    }))
    local debug_path = refactor.ts:get_debug_path(node)

    return iter(debug_path):map(tostring):rev():join("#")
end

---@param refactor refactor.Refactor
---@param opts {below: boolean}
---@return refactor.Point insert_pos
---@return refactor.Point path_pos
---@return TSNode? current_statement
function M.get_debug_points(refactor, opts)
    local cursor = refactor.cursor
    local current_line = api.nvim_buf_get_lines(
        refactor.bufnr,
        cursor.row - 1,
        cursor.row,
        true
    )[1]
    local _, non_white_space = current_line:find("^%s*()") --[[@as integer, integer]]

    local cursor_col = math.max(non_white_space, cursor.col)
    local range = { cursor.row - 1, cursor_col, cursor.row - 1, cursor_col + 1 }
    local language_tree = refactor.ts.language_tree:language_for_range(range)

    assert(language_tree)
    local current =
        language_tree:named_node_for_range(range, { ignore_injections = false })
    assert(current)
    local statements = refactor.ts:get_statements(refactor.root)
    local is_statement = false
    while current and not is_statement do
        is_statement = iter(statements):any(function(node)
            return node:equal(current)
        end)

        if not is_statement then
            current = current:parent()
        end
    end

    local is_indent_scope = current
        and iter(refactor.ts.indent_scopes):any(function(scope)
            return current:type() == scope
        end)

    local insert_pos = cursor:clone()
    -- NOTE: I override the insert_pos col for the sake of clarify, but it's
    -- overriding (in the same way) by `insert_new_line_text` anywaw
    local path_pos = cursor:clone()
    if current and not is_indent_scope then
        local start_row, start_col, end_row, end_col = current:range()
        start_row, end_row = start_row + 1, end_row + 1

        insert_pos.row = opts.below and end_row or start_row
        insert_pos.col = opts.below and end_col or start_col

        path_pos.row = opts.below and end_row or start_row
        path_pos.col = opts.below and vim.v.maxcol or end_col
    else
        insert_pos.col = opts.below and vim.v.maxcol or 0

        path_pos.col = opts.below and vim.v.maxcol or 0

        if current and is_indent_scope then
            local start_row = current:range()

            local below_line = api.nvim_buf_get_lines(
                refactor.bufnr,
                start_row + 1,
                start_row + 2,
                true
            )[1]
            _, non_white_space = below_line:find("^%s*()") --[[@as integer, integer]]

            current = current:named_descendant_for_range(
                start_row + 1,
                non_white_space,
                start_row + 1,
                non_white_space + 1
            ) or current
        end
    end

    return insert_pos, path_pos, current
end

return M
