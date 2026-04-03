local code_utils = require("refactoring.code_generation.utils")

local function dart_function(opts)
    local args = next(opts.args) and table.concat(opts.args, ", ") or ""

    return ([[
%s(%s) {
%s
}

]]):format(opts.name, args, code_utils.stringify_code(opts.body))
end

local function dart_constant(opts)
    local constant_string_pattern

    if opts.multiple then
        constant_string_pattern = ("var %s = %s;\n"):format(
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

        if not opts.statement then
            opts.statement = "var %s = %s;"
        end

        constant_string_pattern = (opts.statement .. "\n"):format(
            name,
            opts.value
        )
    end

    return constant_string_pattern
end

---@type refactor.CodeGeneration
local dart = {
    comment = function(statement)
        return ("// %s"):format(statement)
    end,
    constant = function(opts)
        return dart_constant(opts)
    end,
    ["function"] = dart_function,
    function_return = dart_function,
    ["return"] = function(code)
        return ("return %s;"):format(code_utils.stringify_code(code))
    end,
    call_function = function(opts)
        return ("%s(%s)"):format(opts.name, table.concat(opts.args, ", "))
    end,
    class_function = dart_function,
    class_function_return = dart_function,
    call_class_function = function(opts)
        return ("%s(%s)"):format(opts.name, table.concat(opts.args, ", "))
    end,
    terminate = function(code)
        return code .. ";"
    end,
    pack = function(names)
        return code_utils.returnify(names, "%s")
    end,
    print = function(opts)
        return opts.statement:format(opts.content)
    end,
    default_printf_statement = function()
        return { 'print("%s");' }
    end,
    default_print_var_statement = function()
        return { 'print("%s ${%s}");' }
    end,
    print_var = function(opts)
        return opts.statement:format(opts.prefix, opts.var)
    end,
}

return dart