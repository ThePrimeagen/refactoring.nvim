local code_utils = require("refactoring.code_generation.utils")

local function lua_function(opts)
    return string.format(
        [[
local function %s(%s)
%s
end

]],
        opts.name,
        table.concat(opts.args, ", "),
        code_utils.stringify_code(opts.body)
    )
end

---@param opts constant_opts
---@return string
local function lua_constant(opts)
    local result ---@type string
    if not opts.statement then
        opts.statement = "local %s = %s"
    end

    if opts.multiple then
        result = string.format(
            opts.statement .. "\n",
            table.concat(opts.identifiers, ", "),
            table.concat(opts.values, ", ")
        )
    else
        local name ---@type string
        if opts.name[1] ~= nil then
            name = opts.name[1]
        else
            name = opts.name --[[@as string]]
        end
        result = string.format(opts.statement .. "\n", name, opts.value)
    end

    return result
end

---@type code_generation
local lua = {
    comment = function(statement)
        return string.format("-- %s", statement)
    end,
    default_printf_statement = function()
        return { "print([==[%s]==])" }
    end,
    print = function(opts)
        return string.format(opts.statement, opts.content)
    end,
    default_print_var_statement = function()
        return { "print([==[%s]==], vim.inspect(%s))" }
    end,
    print_var = function(opts)
        return string.format(opts.statement, opts.prefix, opts.var)
    end,
    constant = function(opts)
        return lua_constant(opts)
    end,
    ["function"] = function(opts)
        return lua_function(opts)
    end,
    function_return = function(opts)
        return lua_function(opts)
    end,
    ["return"] = function(code)
        return string.format("return %s", code_utils.stringify_code(code))
    end,

    call_function = function(opts)
        return string.format("%s(%s)", opts.name, table.concat(opts.args, ", "))
    end,
    terminate = function(code)
        return code
    end,
    pack = function(opts)
        return code_utils.returnify(opts, "%s")
    end,
}
return lua
