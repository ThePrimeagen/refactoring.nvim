local utils = require("refactoring.code_generation.utils")

local function get_prefix(start_col)
    local temp = {}
    for i = 1, start_col do
        temp[i] = " "
    end
    return table.concat(temp)
end

local function combine_strings(a, b)
    local temp = {}
    temp[1] = a
    temp[2] = b
    return table.concat(temp)
end

local python = {
    constant = function(opts)
        return combine_strings(
            get_prefix(opts.start_col),
            string.format("%s = %s\n", opts.name, opts.value)
        )
    end,
    ["return"] = function(code)
        return string.format("return %s", utils.stringify_code(code))
    end,

    ["function"] = function(opts)
        return string.format(
            [[
def %s(%s):
    %s


]],
            opts.name,
            table.concat(opts.args, ", "),
            utils.stringify_code(opts.body)
        )
    end,
    call_function = function(opts)
        return string.format("%s(%s)", opts.name, table.concat(opts.args, ", "))
    end,
}
return python
