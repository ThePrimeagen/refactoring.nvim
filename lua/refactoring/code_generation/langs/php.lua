local code_utils = require("refactoring.code_generation.utils")
local code_gen_indent = require("refactoring.code_generation.indent")

local indent_char = " "
local string_pattern = "%s"

local function php_function(opts)
    return string.format(
        [[
public function %s (
    %s
) {
    %s
}

]],
        opts.name,
        table.concat(opts.args, ", "),
        code_utils.stringify_code(opts.body)
    )
end

local php = {
    print = function(statement)
        return string.format('printf("%s\\n");', statement)
    end,
    print_var = function(prefix, var)
        return string.format(
            "printf('%s %%s'.%s, %s);",
            prefix,
            '"\\n"', -- this feels really ugly..
            var
        )
    end,
    comment = function(statement)
        return string.format("// %s", statement)
    end,
    constant = function(opts)
        return string.format(
            "%s = %s;\n",
            code_utils.returnify(opts.name, string_pattern),
            opts.value
        )
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
        return php_function(opts)
    end,
    function_return = function(opts)
        return php_function(opts)
    end,
    call_function = function(opts)
        return string.format(
            "$this->%s(%s)",
            opts.name,
            table.concat(opts.args, ", ")
        )
    end,
    terminate = function(code)
        return code .. ";\n"
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

return php
