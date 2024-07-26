local code_utils = require("refactoring.code_generation.utils")
local ts = require("refactoring.code_generation.langs.typescript")

local function build_args(args, arg_types)
    local final_args = {}
    for i, arg in pairs(args) do
        if arg_types[arg] ~= code_utils.default_func_param_type() then
            final_args[i] = arg .. ": " .. arg_types[arg]
        else
            final_args[i] = arg
        end
    end
    return final_args
end

---@param opts function_opts
local function tsx_function(opts)
    if opts.region_type == "jsx_element" then
        local args
        if opts.args_types ~= nil then
            args = build_args(opts.args, opts.args_types)
        else
            args = opts.args
        end

        return string.format(
            [[
%sfunction %s({%s}) {
return (
<>
%s
</>
)
%s}

]],
            opts.func_header,
            opts.name,
            table.concat(args, ", "),
            code_utils.stringify_code(opts.body),
            opts.func_header
        )
    else
        return ts["function"](opts)
    end
end

---@param opts call_function_opts
local function tsx_call_function(opts)
    if opts.region_type == "jsx_element" or opts.contains_jsx then
        local args = vim.iter(opts.args)
            :map(function(arg)
                return string.format("%s={%s}", arg, arg)
            end)
            :join(" ")
        return string.format("< %s %s/>", opts.name, args)
    else
        return ts.call_function(opts)
    end
end

local special_nodes = {
    "jsx_element",
    "jsx_self_closing_element",
}

---@param var string
---@param opts special_var_opts
---@return string
local function tsx_special_var(var, opts)
    if vim.tbl_contains(special_nodes, opts.region_node_type) then
        return string.format("{%s}", var)
    else
        return var
    end
end

---@type code_generation
local tsx = {
    default_printf_statement = ts.default_printf_statement,
    print = ts.print,
    default_print_var_statement = ts.default_print_var_statement,
    print_var = ts.print_var,
    comment = ts.comment,
    constant = ts.constant,
    special_var = tsx_special_var,
    pack = ts.pack,

    unpack = ts.unpack,

    ["return"] = ts["return"],
    ["function"] = tsx_function,
    function_return = ts.function_return,
    call_function = tsx_call_function,
    -- Shouldn't add a semicolon inside of JSX/TSX
    terminate = function(code)
        return code
    end,

    class_function = ts.class_function,

    class_function_return = ts.class_function_return,

    call_class_function = ts.call_class_function,
}

return tsx
