local code_utils = require("refactoring.code_generation.utils")

local string_pattern = "%s"

local function php_function(opts)
    if opts.func_header == nil then
        opts.func_header = ""
    end
    return string.format(
        [[
%sfunction %s (
%s    %s
%s) {
%s
%s}
]],
        opts.func_header,
        opts.name,
        opts.func_header,
        table.concat(opts.args, ", "),
        opts.func_header,
        code_utils.stringify_code(opts.body),
        opts.func_header
    )
end

local function php_class_function(opts)
    if opts.func_header == nil then
        opts.func_header = ""
    end

    return string.format(
        [[
%s%s function %s (
%s    %s
%s) {
%s
%s}
]],
        opts.func_header,
        opts.visibility,
        opts.name,
        opts.func_header,
        table.concat(opts.args, ", "),
        opts.func_header,
        code_utils.stringify_code(opts.body),
        opts.func_header
    )
end

---@type code_generation
local php = {
    default_print_var_statement = function()
        return { "printf('%s %%s'.%s, %s);" }
    end,
    print_var = function(opts)
        return string.format(
            opts.statement,
            opts.prefix,
            '"\\n"', -- this feels really ugly..
            opts.var
        )
    end,
    default_printf_statement = function()
        return { 'printf("%s\\n");' }
    end,
    print = function(opts)
        return string.format(opts.statement, opts.content)
    end,
    comment = function(statement)
        return string.format("// %s", statement)
    end,
    constant = function(opts)
        if not opts.statement then
            opts.statement = "%s = %s;"
        end
        return string.format(
            opts.statement .. "\n",
            code_utils.returnify(opts.name, string_pattern),
            opts.value
        )
    end,
    pack = function(names)
        return code_utils.returnify(names, string_pattern)
    end,

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
        return string.format("%s(%s)", opts.name, table.concat(opts.args, ", "))
    end,
    terminate = function(code)
        return code .. ";"
    end,
    class_function = function(opts)
        return php_class_function(opts)
    end,
    class_function_return = function(opts)
        return php_class_function(opts)
    end,
    call_class_function = function(opts)
        return string.format(
            "$this->%s(%s)",
            opts.name,
            table.concat(opts.args, ", ")
        )
    end,
}

return php
