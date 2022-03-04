local code_utils = require("refactoring.code_generation.utils")
local code_gen_indent = require("refactoring.code_generation.indent")

local function lua_function(opts)
    return string.format(
        [[
local function %s(%s)
%s
end

]],
        opts.name,
        table.concat(opts.args, ", "),
        code_utils.stringify_code(opts.body)
    )
end

local function lua_constant(opts)
    local constant_string_pattern

    if opts.multiple then
        constant_string_pattern = string.format(
            "local %s = %s\n",
            table.concat(opts.identifiers, ", "),
            table.concat(opts.values, ", ")
        )
    else
        local name
        if opts.name[1] ~= nil then
            name = opts.name[1]
        else
            name = opts.name
        end
        constant_string_pattern = string.format(
            "local %s = %s\n",
            name,
            opts.value
        )
    end

    return constant_string_pattern
end

local indent_char = " "

local lua = {
    comment = function(statement)
        return string.format("-- %s", statement)
    end,
    ["print"] = function(print_string)
        return string.format('print("%s")', print_string)
    end,
    print_var = function(prefix, var)
        return string.format('print("%s", vim.inspect(%s))', prefix, var)
    end,
    constant = function(opts)
        return lua_constant(opts)
    end,
    ["function"] = function(opts)
        return lua_function(opts)
    end,
    function_return = function(opts)
        return lua_function(opts)
    end,
    ["return"] = function(code)
        return string.format("return %s", code_utils.stringify_code(code))
    end,

    call_function = function(opts)
        return string.format("%s(%s)", opts.name, table.concat(opts.args, ", "))
    end,
    terminate = function(code)
        return code .. "\n"
    end,
    pack = function(opts)
        return code_utils.returnify(opts, "%s")
    end,
    indent_char_length = function(first_line)
        return code_gen_indent.indent_char_length(first_line, indent_char)
    end,
    indent_char = function()
        return indent_char
    end,
    indent = function(opts)
        return code_gen_indent.indent(opts, indent_char)
    end,
}
return lua
