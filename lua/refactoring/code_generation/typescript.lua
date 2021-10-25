local code_utils = require("refactoring.code_generation.utils")

local typescript = {
    constant = function(opts)
        return string.format("const %s = %s;\n", opts.name, opts.value)
    end,

    ["return"] = function(code)
        if type(code) == "table" and #code == 1 then
            code = code[1]
        end

        if  type(code) == "string" then
            return string.format("return %s", code_utils.stringify_code(code))
        end

        local codes = {}
        for _, value in pairs(code) do
            table.insert(codes, code_utils.stringify_code(value))
        end
        return string.format("return {%s}", table.concat(codes, ", "))
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
}

return typescript
