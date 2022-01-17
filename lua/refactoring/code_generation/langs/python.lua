local code_utils = require("refactoring.code_generation.utils")

local function python_function(opts)
    return string.format(
        [[
def %s(%s):
    %s


]],
        opts.name,
        table.concat(opts.args, ", "),
        code_utils.stringify_code(opts.body)
    )
end

local function python_class_function(opts)
    return string.format(
        [[
def %s(self, %s):
    %s


]],
        opts.name,
        table.concat(opts.args, ", "),
        code_utils.stringify_code(opts.body)
    )
end

local function python_constant(opts)
    local constant_string_pattern

    if opts.multiple then
        constant_string_pattern = string.format(
            "%s = %s\n",
            table.concat(opts.identifiers, ", "),
            table.concat(opts.values, ", ")
        )
    else
        constant_string_pattern = string.format(
            "%s = %s\n",
            opts.name,
            opts.value
        )
    end

    return constant_string_pattern
end

local python = {
    constant = function(opts)
        return python_constant(opts)
    end,
    ["return"] = function(code)
        return string.format("return %s", code_utils.stringify_code(code))
    end,
    ["function"] = function(opts)
        return python_function(opts)
    end,
    function_return = function(opts)
        return python_function(opts)
    end,
    call_function = function(opts)
        return string.format("%s(%s)", opts.name, table.concat(opts.args, ", "))
    end,
    class_function = function(opts)
        return python_class_function(opts)
    end,
    call_class_function = function(opts)
        return string.format(
            "self.%s(%s)",
            opts.name,
            table.concat(opts.args, ", ")
        )
    end,

    terminate = function(code)
        return code .. "\n"
    end,
    pack = function(opts)
        return code_utils.returnify(opts, "%s")
    end,
    comment = function(statement)
        return string.format("# %s", statement)
    end,
    print = function(statement)
        return string.format('print(f"%s")', statement)
    end,
    print_var = function(prefix, var)
        return string.format('print(f"%s {str(%s)}")', prefix, var)
    end,
}
return python
