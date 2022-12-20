local code_utils = require("refactoring.code_generation.utils")
local code_gen_indent = require("refactoring.code_generation.indent")

local function ruby_function(opts)
    local singleton = opts.scope_type == "singleton_method"
    local name = singleton and "self." .. opts.name or opts.name
    local args = next(opts.args) and table.concat(opts.args, ", ") or ""

    return string.format(
        [[
def %s(%s)
%s
end

]],
        name,
        args,
        code_utils.stringify_code(opts.body)
    )
end

local function ruby_constant(opts)
    local constant_string_pattern

    if opts.multiple then
        constant_string_pattern = string.format(
            "%s = %s\n",
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
        constant_string_pattern = string.format("%s = %s\n", name, opts.value)
    end

    return constant_string_pattern
end

local indent_char = " "

local ruby = {
    comment = function(statement)
        return string.format("# %s", statement)
    end,
    constant = function(opts)
        return ruby_constant(opts)
    end,
    ["function"] = ruby_function,
    function_return = ruby_function,
    ["return"] = function(code)
        return string.format("%s", code_utils.stringify_code(code))
    end,
    call_function = function(opts)
        return string.format("%s(%s)", opts.name, table.concat(opts.args, ", "))
    end,
    class_function = ruby_function,
    class_function_return = ruby_function,
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
        return { 'puts "%s #{%s}"' }
    end,
    print_var = function(opts)
        return string.format(opts.statement, opts.prefix, opts.var)
    end,
}

return ruby
