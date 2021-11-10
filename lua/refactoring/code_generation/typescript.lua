local code_utils = require("refactoring.code_generation.utils")

local function returnify(args)
    if type(args) == "string" then
        return args
    end

    if #args == 1 then
        return args[1]
    end

    local codes = {}
    for _, value in pairs(args) do
        table.insert(codes, code_utils.stringify_code(value))
    end

    return string.format("{%s}", table.concat(codes, ", "))
end

local typescript = {
    print = function(statement)
        return string.format("console.log(\"%s\");", statement)
    end,

    -- The constant can be destructured
    constant = function(opts)
        return string.format(
            "const %s = %s;\n",
            returnify(opts.name),
            opts.value
        )
    end,

    -- This is for returing multiple arguments from a function
    -- @param names string|table
    pack = function(names)
        return returnify(names)
    end,

    -- this is for consuming one or more arguments from a function call.
    -- @param names string|table
    unpack = function(names)
        return returnify(names)
    end,

    ["return"] = function(code)
        return string.format("return %s;", code)
    end,

    ["function"] = function(opts)
        return string.format(
            [[
function %s(%s) {
    %s
}

]],
            opts.name,
            table.concat(opts.args, ", "),
            code_utils.stringify_code(opts.body)
        )
    end,

    call_function = function(opts)
        return string.format("%s(%s)", opts.name, table.concat(opts.args, ", "))
    end,
    terminate = function(code)
        return code .. ";\n"
    end,
}

return typescript
