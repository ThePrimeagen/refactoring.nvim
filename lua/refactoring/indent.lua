local iter = vim.iter
local ts = vim.treesitter

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
    ---@type string[]
    local indent = {}

    ---@type string[]
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
    ---@type string[]
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
