local Region = require("refactoring.region")

local M = {}

---Returns the indent width of a given buffer
---
---This depends on the values of `shiftwidth` and `tabstop` for the buffer
---@param bufnr number
---@return number
M.buf_indent_width = function(bufnr)
    local efective_shiftwidth = vim.bo[bufnr].shiftwidth > 0
            and vim.bo[bufnr].shiftwidth
        or vim.bo[bufnr].tabstop
    return efective_shiftwidth
end

---@param point RefactorPoint
---@param refactor Refactor
---@param below boolean
---@param bufnr number
---@return number
M.buf_indent_amount = function(point, refactor, below, bufnr)
    local region = Region:from_point(point, bufnr)
    local region_node = region:to_ts_node(refactor.ts:get_root())

    local scope = refactor.ts:get_scope(region_node)

    if not scope then
        return refactor.whitespace.cursor / M.buf_indent_width(refactor.bufnr)
    end

    --- @type TSNode[]
    local nodes = {}
    local statements = refactor.ts:get_statements(scope)
    for _, node in ipairs(statements) do
        table.insert(nodes, node)
    end
    local function_body = refactor.ts:get_function_body(scope)
    for _, node in ipairs(function_body) do
        table.insert(nodes, node)
    end

    if #nodes == 0 then
        return refactor.whitespace.cursor / M.buf_indent_width(refactor.bufnr)
    end

    --- @type integer[]
    local line_numbers = {}
    for _, node in ipairs(nodes) do
        local start_row, _, end_row, _ = node:range()
        table.insert(line_numbers, start_row + 1)
        table.insert(line_numbers, end_row + 1)
    end

    ---@type table<integer, boolean>
    local already_seend = {}
    line_numbers = vim.iter(line_numbers)
        :filter(
            ---@param line_number integer
            ---@return boolean
            function(line_number)
                if already_seend[line_number] then
                    return false
                end
                already_seend[line_number] = true
                local distance = point.row - line_number
                return distance ~= 0
            end
        )
        :totable()

    local line_numbers_up = vim.iter(line_numbers)
        :filter(
            ---@param line_number integer
            ---@return boolean
            function(line_number)
                local distance = point.row - line_number
                return distance > 0
            end
        )
        :totable()
    local line_numbers_down = vim.iter(line_numbers)
        :filter(
            ---@param line_number integer
            ---@return boolean
            function(line_number)
                local distance = point.row - line_number
                return distance < 0
            end
        )
        :totable()

    ---@param a integer
    ---@param b integer
    ---@return boolean
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

    --- @type integer
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

---Returns indent amount of a given line in a given buffer
---
---Indent amount: the number of indents (tab or space) at the beginning of the line
---
---Two  spaces => one indent amount (expandtab = true, shiftwidth = 2)
---Four spaces => one indent amount (expandtab = true, shiftwidth = 4)
---Four spaces => two indent amount (expandtab = true, shiftwidth = 2)
---Two  tabs   => two indent amount (expandtab = false, shiftwidth = 8, tabstop=8)
---Four tabs   => four indent amount (expandtab = false, shiftwidth = 4, tabstop=4)
---Four tabs   => four indent amount (expandtab = false, shiftwidth = 8, tabstop=8)
---
---This depends on the values of `expandtab`, `shiftwidth` and `tabstop` for the buffer
---@param line string
---@param bufnr number
---@return number
M.line_indent_amount = function(line, bufnr)
    return M.line_indent_width(line, bufnr) / M.buf_indent_width(bufnr)
end

---Returns indent width of a given line in a given buffer
---
---Indent width: the number of indents (tab or space) at the beginning of the line
---
---Two  spaces => two indent width
---Four spaces => four indent width
---Two  tabs   => two indent width
---Four tabs   => four indent width
---@param line string
---@param bufnr number
---@return number
M.line_indent_width = function(line, bufnr)
    local indent_char = M.indent_char(bufnr)
    local whitespace = 0
    for char in line:gmatch(".") do
        if char ~= indent_char then
            break
        end
        whitespace = whitespace + 1
    end
    return whitespace
end

---@param indent_amount number
---@param bufnr number
---@return string
local function space_indent(indent_amount, bufnr)
    --- @type string[]
    local indent = {}

    --- @type string[]
    local single_indent_table = {}
    for i = 1, M.buf_indent_width(bufnr) do
        single_indent_table[i] = " "
    end
    local single_indent = table.concat(single_indent_table, "")

    for i = 1, indent_amount do
        indent[i] = single_indent
    end

    return table.concat(indent, "")
end

---@param indent_amount number
---@return string
local function tab_indent(indent_amount)
    --- @type string[]
    local indent = {}
    for i = 1, indent_amount do
        indent[i] = "\t"
    end
    return table.concat(indent, "")
end

---@param indent_amount number
---@param bufnr number
---@return string
M.indent = function(indent_amount, bufnr)
    local use_spaces = vim.bo[bufnr].expandtab

    if use_spaces then
        return space_indent(indent_amount, bufnr)
    else
        return tab_indent(indent_amount)
    end
end

---@param bufnr number
---@return string
M.indent_char = function(bufnr)
    return vim.bo[bufnr].expandtab and " " or "\t"
end

---@param lines string[]
---@param start number
---@param finish number
---@param indent_amount number
---@param bufnr number
M.lines_remove_indent = function(lines, start, finish, indent_amount, bufnr)
    local effective_indent = indent_amount * M.buf_indent_width(bufnr)

    for i = start, finish do
        lines[i] = lines[i]:sub(effective_indent + 1, #lines[i])
    end
end

return M
