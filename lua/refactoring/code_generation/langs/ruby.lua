local code_utils = require("refactoring.code_generation.utils")
local code_gen_indent = require("refactoring.code_generation.indent")

local indent_char = " "
local string_pattern = "%s"

local function ruby_function_with_params(opts)
    return string.format(
        [[
def %s(%s)
  %s
end
]],
        opts.name,
        table.concat(opts.args, ", "),
        code_utils.stringify_code(opts.body)
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
        code_utils.stringify_code(opts.body)
    )
end

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

    -- This is for returing multiple arguments from a function
    -- @param names string|table
    pack = function(names)
        return code_utils.returnify(names, string_pattern)
    end,
    ["return"] = function(code)
        return string.format("%s", code)
    end,
    ["function"] = function(opts)
        return ruby_function(opts)
    end,
    function_return = function(opts)
        return ruby_function(opts)
    end,
    call_function = function(opts)
        if not next(opts.args) then
            return string.format("%s", opts.name)
        else
            return string.format(
                "%s(%s)",
                opts.name,
                table.concat(opts.args, ", ")
            )
        end
    end,

    terminate = function(code)
        return code .. "\n"
    end,
    indent_char_length = function(first_line)
        return code_gen_indent.indent_char_length(first_line, indent_char)
    end,
    indent_char = function()
        return indent_char
    end,
    indent = function(opts)
        return code_gen_indent.indent(opts, indent_char)
    end,
}

return ruby
