local utils = require("refactoring.code_generation.utils")

-- Only use parens when there are parameters
local function ruby_call_function(opts)
    if not next(opts.args) then
        return string.format("%s", opts.name)
    else
        return string.format("%s(%s)", opts.name, table.concat(opts.args, ", "))
    end
end


local function ruby_function_with_params(opts)
        return string.format(
            [[
def %s(%s)
  %s
end

]],
            opts.name,
            table.concat(opts.args, ", "),
            utils.stringify_code(opts.body)
        )
end

local function ruby_function_no_params(opts)
        return string.format(
            [[
def %s
  %s
end

]],
            opts.name,
            utils.stringify_code(opts.body)
        )
end
--
-- Only use parens when there are parameters
local function ruby_function(opts)
    if not next(opts.args) then
        return ruby_function_no_params(opts)
    else
        return ruby_function_with_params(opts)
    end
end

local ruby = {
    constant = function(opts)
        return string.format("%s = %s\n", opts.name, opts.value)
    end,

    ["function"] = function(opts)
        return ruby_function(opts)
    end,
    call_function = function(opts)
        return ruby_call_function(opts)
    end,

    terminate = function(code)
        return code .. "\n"
    end,
}
return ruby
