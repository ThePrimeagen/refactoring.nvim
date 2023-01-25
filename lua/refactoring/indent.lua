local Region = require("refactoring.region")

local M = {}

--- return the indent width of a given buffer
---
--- If the buffer uses tabs ('noexpandtab'), the value uf 'tabstop' will be
-- returned, else the value of 'shiftwidth' will be returned
---@param bufnr number
---@return number
M.buf_indent_width = function(bufnr)
    return vim.bo[bufnr].expandtab and vim.bo[bufnr].shiftwidth
        or vim.bo[bufnr].tabstop
end

M.buf_indent_amount = function(point, refactor, below, bufnr)
    local region = Region:from_point(point, bufnr)
    local region_node = region:to_ts_node(refactor.ts:get_root())

    local scope = refactor.ts:get_scope(region_node)

    local nodes = {}
    local statements = refactor.ts:get_statements(scope)
    for _, node in ipairs(statements) do
        table.insert(nodes, node)
    end
    local function_body = refactor.ts:get_function_body(scope)
    for _, node in ipairs(function_body) do
        table.insert(nodes, node)
    end
    -- TODO: if nodes is emtpy, just use the indent of the cursor
    -- return refactor.whitespace.cursor / indent.buf_indent_width(refactor.bufnr)

    local line_numbers = {}
    for _, node in ipairs(nodes) do
        local start_row, _, end_row, _ = node:range()
        table.insert(line_numbers, start_row + 1)
        table.insert(line_numbers, end_row + 1)
    end

    local hash = {}
    line_numbers = vim.tbl_filter(function(line_number)
        if hash[line_number] then
            return false
        end
        hash[line_number] = true
        local distance = point.row - line_number
        return distance ~= 0
    end, line_numbers)

    local line_numbers_up = vim.tbl_filter(function(line_number)
        local distance = point.row - line_number
        return distance > 0
    end, line_numbers)
    local line_numbers_down = vim.tbl_filter(function(line_number)
        local distance = point.row - line_number
        return distance < 0
    end, line_numbers)

    local sort = function(a, b)
        local a_distance = math.abs(point.row - a)
        local b_distance = math.abs(point.row - b)
        return a_distance < b_distance
    end
    table.sort(line_numbers_up, sort)
    table.sort(line_numbers_down, sort)

    local line_up = line_numbers_up[1]
    local line_down = line_numbers_down[1]

    local line_down_indent = vim.fn.indent(line_down)
    local line_up_indent = vim.fn.indent(line_up)
    local cursor_indent = vim.fn.indent(point.row)

    local indent_scope_whitespace
    if below then
        if cursor_indent == 0 then
            indent_scope_whitespace = math.max(line_down_indent, line_up_indent)
        else
            indent_scope_whitespace = math.max(cursor_indent, line_down_indent)
        end
    else
        if cursor_indent == 0 then
            indent_scope_whitespace = math.max(line_down_indent, line_up_indent)
        else
            indent_scope_whitespace = math.max(cursor_indent, line_up_indent)
        end
    end

    return indent_scope_whitespace / M.buf_indent_width(refactor.bufnr)
end

return M
