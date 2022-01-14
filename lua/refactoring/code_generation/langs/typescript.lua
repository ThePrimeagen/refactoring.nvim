local code_utils = require("refactoring.code_generation.utils")

local string_pattern = "{%s}"

local function typescript_class_function(opts)
    if opts.func_header == nil then
        opts.func_header = ""
    end
    return string.format(
        [[
%s(%s) {
%s
}
]],
        opts.name,
        table.concat(opts.args, ", "),
        code_utils.stringify_code(opts.body)
    )
end

local function typescript_function(opts)
    return string.format(
        [[
function %s(%s) {
%s
}

]],
        opts.name,
        table.concat(opts.args, ", "),
        code_utils.stringify_code(opts.body)
    )
end

local function typescript_constant(opts)
    local constant_string_pattern

    if opts.multiple then
        constant_string_pattern = "const "

        for idx, identifier in pairs(opts.identifiers) do
            if idx == #opts.identifiers then
                constant_string_pattern = constant_string_pattern
                    .. string.format("%s = %s", identifier, opts.values[idx])
            else
                constant_string_pattern = constant_string_pattern
                    .. string.format("%s = %s,", identifier, opts.values[idx])
            end
        end

        constant_string_pattern = constant_string_pattern .. ";\n"
    else
        constant_string_pattern = string.format(
            "const %s = %s;\n",
            code_utils.returnify(opts.name, string_pattern),
            opts.value
        )
    end

    return constant_string_pattern
end

local typescript = {
    print = function(statement)
        return string.format('console.log("%s");', statement)
    end,
    print_var = function(prefix, var)
        return string.format('console.log("%s %%s", %s);', prefix, var)
    end,
    comment = function(statement)
        return string.format("// %s", statement)
    end,
    -- The constant can be destructured
    constant = function(opts)
        return typescript_constant(opts)
    end,

    -- This is for returing multiple arguments from a function
    -- @param names string|table
    pack = function(names)
        return code_utils.returnify(names, string_pattern)
    end,

    -- this is for consuming one or more arguments from a function call.
    -- @param names string|table
    unpack = function(names)
        return code_utils.returnify(names, string_pattern)
    end,

    ["return"] = function(code)
        return string.format("return %s;", code)
    end,
    ["function"] = function(opts)
        return typescript_function(opts)
    end,
    function_return = function(opts)
        return typescript_function(opts)
    end,
    call_function = function(opts)
        return string.format("%s(%s)", opts.name, table.concat(opts.args, ", "))
    end,
    terminate = function(code)
        return code .. ";\n"
    end,
    indent_char_length = function(first_line)
        local whitespace = 0
        for char in first_line:gmatch(".") do
            if char ~= " " then
                break
            end
            whitespace = whitespace + 1
        end
        return whitespace
    end,
    indent_char = function()
        return " "
    end,
    indent = function(opts)
        local indent = {}

        local single_indent_table = {}
        local i = 1
        -- lua loops are weird, adding 1 for correct value
        while i < opts.indent_width + 1 do
            single_indent_table[i] = " "
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
    end,

    class_function = function(opts)
        return typescript_class_function(opts)
    end,

    class_function_return = function(opts)
        return typescript_class_function(opts)
    end,

    call_class_function = function(opts)
        return string.format(
            "this.%s(%s)",
            opts.name,
            table.concat(opts.args, ", ")
        )
    end,
}

return typescript
