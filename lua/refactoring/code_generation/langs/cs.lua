local code_utils = require("refactoring.code_generation.utils")

local string_pattern = "%s"

---@param args string[]
---@return string[]
local function cs_func_args_default_types(args)
    local new_args = {}
    for _, arg in ipairs(args) do
        table.insert(
            new_args,
            ("%s %s"):format(code_utils.default_func_param_type(), arg)
        )
    end
    return new_args
end

---@param args string[]
---@param args_types string[]
---@return string
local function cs_func_args_with_types(args, args_types)
    local args_with_types = {}
    for _, arg in ipairs(args) do
        table.insert(args_with_types, ("%s %s"):format(args_types[arg], arg))
    end
    return table.concat(args_with_types, ", ")
end

---@param opts function_opts
local function cs_func_args(opts)
    if opts.args_types ~= nil then
        return cs_func_args_with_types(opts.args, opts.args_types)
    else
        return table.concat(cs_func_args_default_types(opts.args), ", ")
    end
end

---@param opts constant_opts
---@return string
local function cs_constant(opts)
    local constant_string_pattern ---@type string

    if opts.multiple then
        constant_string_pattern = "var "

        for idx, identifier in pairs(opts.identifiers) do
            if idx == #opts.identifiers then
                constant_string_pattern = constant_string_pattern
                    .. ("%s = %s"):format(identifier, opts.values[idx])
            else
                constant_string_pattern = constant_string_pattern
                    .. ("%s = %s,"):format(identifier, opts.values[idx])
            end
        end

        constant_string_pattern = constant_string_pattern .. ";\n"
    else
        if not opts.statement then
            opts.statement = "var %s = %s;"
        end

        constant_string_pattern = (opts.statement .. "\n"):format(
            code_utils.returnify(opts.name, string_pattern),
            opts.value
        )
    end

    return constant_string_pattern
end

---@type code_generation
local cs = {
    comment = function(statement)
        return ("// %s"):format(statement)
    end,
    default_printf_statement = function()
        return { 'Console.WriteLine(@"%s");' }
    end,
    print = function(opts)
        return opts.statement:format(opts.content)
    end,
    default_print_var_statement = function()
        return { 'Console.WriteLine($"%s {%s}");' }
    end,
    print_var = function(opts)
        return opts.statement:format(opts.prefix, opts.var)
    end,
    ["return"] = function(code)
        return ("return %s;"):format(code)
    end,
    ["function"] = function(opts)
        return ([[
public static void %s(%s) {
%s
}

]]):format(
            opts.name,
            cs_func_args(opts),
            code_utils.stringify_code(opts.body)
        )
    end,
    function_return = function(opts)
        return ([[
public static %s %s(%s) {
%s
}

]]):format(
            opts.return_type,
            opts.name,
            cs_func_args(opts),
            code_utils.stringify_code(opts.body)
        )
    end,
    constant = function(opts)
        return cs_constant(opts)
    end,
    call_function = function(opts)
        return ("%s(%s)"):format(opts.name, table.concat(opts.args, ", "))
    end,
    pack = function(opts)
        return code_utils.returnify(opts, "%s")
    end,
    terminate = function(code)
        return code .. ";"
    end,
}

return cs
