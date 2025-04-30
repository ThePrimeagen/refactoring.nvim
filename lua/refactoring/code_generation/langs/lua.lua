local code_utils = require("refactoring.code_generation.utils")

---@param opts refactor.FuncParams
---@return string
local function lua_function(opts)
    return ([[
local function %s(%s)
%s
end

]]):format(
        opts.name,
        table.concat(opts.args, ", "),
        code_utils.stringify_code(opts.body)
    )
end

---@param opts refactor.code_gen.constant.Opts
---@return string
local function lua_constant(opts)
    local result ---@type string
    if not opts.statement then
        opts.statement = "local %s = %s"
    end

    if opts.multiple then
        result = (opts.statement .. "\n"):format(
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
        result = (opts.statement .. "\n"):format(name, opts.value)
    end

    return result
end

---@type refactor.CodeGeneration
local lua = {
    comment = function(statement)
        return ("-- %s"):format(statement)
    end,
    default_printf_statement = function()
        return { "print([==[%s]==])" }
    end,
    print = function(opts)
        return opts.statement:format(opts.content)
    end,
    default_print_var_statement = function()
        return { "print([==[%s]==], vim.inspect(%s))" }
    end,
    print_var = function(opts)
        return opts.statement:format(opts.prefix, opts.var)
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
        return ("return %s"):format(code_utils.stringify_code(code))
    end,

    call_function = function(opts)
        return ("%s(%s)"):format(opts.name, table.concat(opts.args, ", "))
    end,
    terminate = function(code)
        return code
    end,
    pack = function(opts)
        return code_utils.returnify(opts, "%s")
    end,
}
return lua
