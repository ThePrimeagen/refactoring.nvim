local code_utils = require("refactoring.code_generation.utils")

local string_pattern = "%s"

local function php_function(opts)
    if opts.func_header == nil then
        opts.func_header = ""
    end
    return ([[
%sfunction %s (
%s    %s
%s) {
%s
%s}
]]):format(
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

    return ([[
%s%s function %s (
%s    %s
%s) {
%s
%s}
]]):format(
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
        return opts.statement:format(
            opts.prefix,
            '"\\n"', -- this feels really ugly..
            opts.var
        )
    end,
    default_printf_statement = function()
        return { 'printf("%s\\n");' }
    end,
    print = function(opts)
        return opts.statement:format(opts.content)
    end,
    comment = function(statement)
        return ("// %s"):format(statement)
    end,
    constant = function(opts)
        if not opts.statement then
            opts.statement = "%s = %s;"
        end
        return (opts.statement .. "\n"):format(
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
        return ("return %s;"):format(code)
    end,
    ["function"] = function(opts)
        return php_function(opts)
    end,
    function_return = function(opts)
        return php_function(opts)
    end,
    call_function = function(opts)
        return ("%s(%s)"):format(opts.name, table.concat(opts.args, ", "))
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
        return ("$this->%s(%s)"):format(
            opts.name,
            table.concat(opts.args, ", ")
        )
    end,
}

return php
