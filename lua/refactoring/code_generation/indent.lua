local M = {}

-- TODO: Fix function name
function M.indent_char_length(first_line, indent_char)
    local whitespace = 0
    for char in first_line:gmatch(".") do
        if char ~= indent_char then
            break
        end
        whitespace = whitespace + 1
    end
    return whitespace
end

function M.indent(opts, indent_char)
    local indent = {}

    local single_indent_table = {}
    local i = 1
    -- lua loops are weird, adding 1 for correct value
    while i < opts.indent_width + 1 do
        single_indent_table[i] = indent_char
        i = i + 1
    end
    local single_indent = table.concat(single_indent_table, "")

    i = 1
    -- lua loops are weird, adding 1 for correct value
    while i < opts.indent_amount + 1 do
        indent[i] = single_indent
        i = i + 1
    end

    return table.concat(indent, "")
end

return M
