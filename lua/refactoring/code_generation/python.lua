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

    return string.format("%s", table.concat(codes, ", "))
end

local python = {
    constant = function(opts)
        return string.format("%s = %s\n", opts.name, opts.value)
    end,
    ["return"] = function(code)
        return string.format("return %s", code_utils.stringify_code(code))
    end,

    ["function"] = function(opts)
        return string.format(
            [[
def %s(%s):
    %s


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
        return code .. "\n"
    end,
    pack = function(opts)
        return returnify(opts)
    end,
}
return python
