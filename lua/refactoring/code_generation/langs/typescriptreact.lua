local code_utils = require("refactoring.code_generation.utils")
local ts = require("refactoring.code_generation.langs.typescript")

---@param args string[]
---@param arg_types table<string, string>
---@return string[]
local function build_args(args, arg_types)
    local final_args = {} ---@type string[]
    for i, arg in pairs(args) do
        if arg_types[arg] ~= code_utils.default_func_param_type() then
            final_args[i] = arg .. ": " .. arg_types[arg]
        else
            final_args[i] = arg
        end
    end
    return final_args
end

---@param opts refactor.code_gen.function.Opts
local function tsx_function(opts)
    if opts.region_type ~= "jsx_element" then
        return ts["function"](opts)
    end

    local args ---@type string[]
    if opts.args_types ~= nil then
        args = build_args(opts.args, opts.args_types)
    else
        args = opts.args
    end
    assert(args)

    return ([[
%sfunction %s({%s}) {
return (
<>
%s
</>
)
%s}

]]):format(
        opts.func_header,
        opts.name,
        table.concat(args, ", "),
        code_utils.stringify_code(opts.body),
        opts.func_header
    )
end

---@param opts refactor.code_gen.call_function.Opts
local function tsx_call_function(opts)
    if opts.region_type == "jsx_element" or opts.contains_jsx then
        local args = vim.iter(opts.args)
            :map(function(arg)
                return ("%s={%s}"):format(arg, arg)
            end)
            :join(" ")
        return ("< %s %s/>"):format(opts.name, args)
    else
        return ts.call_function(opts)
    end
end

local special_nodes = {
    "jsx_element",
    "jsx_self_closing_element",
}

---@param var string
---@param opts refactor.code_gen.special_var.Opts
---@return string
local function tsx_special_var(var, opts)
    if vim.tbl_contains(special_nodes, opts.region_node_type) then
        return ("{%s}"):format(var)
    else
        return var
    end
end

---@type refactor.CodeGeneration
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
