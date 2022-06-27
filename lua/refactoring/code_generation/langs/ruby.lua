local code_utils = require("refactoring.code_generation.utils")
local code_gen_indent = require("refactoring.code_generation.indent")

local function ruby_function_with_params(opts)
    return string.format(
        [[
def %s(%s)
%s
end

]],
        opts.name,
        table.concat(opts.args, ", "),
        code_utils.stringify_code(opts.body)
    )
end

local function ruby_function_no_params(opts)
    return string.format(
        [[
def %s
%s
end

]],
        opts.name,
        code_utils.stringify_code(opts.body)
    )
end

local function ruby_function(opts)
    if not next(opts.args) then
        return ruby_function_no_params(opts)
    else
        return ruby_function_with_params(opts)
    end
end

local function ruby_class_function(opts)
    return ruby_function(opts)
end

local indent_char = " "

local ruby = {
    comment = function(statement)
        return string.format("# %s", statement)
    end,
    constant = function(opts)
        return string.format("%s = %s\n", opts.name, opts.value)
    end,
    ["function"] = function(opts)
        return ruby_function(opts)
    end,
    function_return = function(opts)
        return ruby_function(opts)
    end,
    ["return"] = function(code)
        return string.format("%s", code_utils.stringify_code(code))
    end,
    call_function = function(opts)
        return string.format("%s(%s)", opts.name, table.concat(opts.args, ", "))
    end,
    class_function = function(opts)
        return ruby_class_function(opts)
    end,
    class_function_return = function(opts)
        return ruby_class_function(opts)
    end,
    call_class_function = function(opts)
        return string.format("%s(%s)", opts.name, table.concat(opts.args, ", "))
    end,
    terminate = function(code)
        return code
    end,
    -- This is for returing multiple arguments from a function
    -- @param names string|table
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
    print = function(opts)
        return string.format(opts.statement, opts.content)
    end,
    default_printf_statement = function()
        return { 'puts "%s"' }
    end,
    default_print_var_statement = function()
        return { 'puts "%s {str(%s)}"' }
    end,
    print_var = function(opts)
        return string.format(opts.statement, opts.prefix, opts.var)
    end,
}

return ruby
