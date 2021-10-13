local utils = require("refactoring.code_generation.utils")


-- Only moving here because of circular dependency
-- with config, codegen, get_input
local function get_input(question, text)
    text = text or ""

    local a = {}
    if a.inputs then
        local inputs = a.inputs
        if #inputs > a.inputs_idx then
            a.inputs_idx = a.inputs_idx + 1
            return a.inputs[a.inputs_idx]
        end
    end

    return vim.fn.input(question, text)
end

local function get_return(code)
    return string.format("return %s", utils.stringify_code(code))
end

local function create_function_no_return_text(opts)
        return string.format(
[[
func %s(%s) {
    %s
}
]],
        opts.name,
        table.concat(opts.args, ", "),
        utils.stringify_code(opts.body)
    )
end

local function create_function_text_with_return(opts, return_type)
    table.insert(opts.body, get_return("fill_me"))
    return string.format(
[[
func %s(%s) %s {
    %s
}
]],
        opts.name,
        table.concat(opts.args, ", "),
        return_type,
        utils.stringify_code(opts.body)
    )
end

local function create_function(opts)
    local result = nil
    if opts.ask_return then
        local return_type = get_input("106 golang: function return type > ")
        if return_type == "" then
            result = create_function_no_return_text(opts)
        else
            result = create_function_text_with_return(opts, return_type)
        end
    else
        result = create_function_no_return_text(opts)
    end

    return result
end

local go = {
    constant = function(opts)
        return string.format("%s := %s\n", opts.name, opts.value)
    end,
    ["return"] = function(code)
        return get_return(code)
    end,
    ["function"] = function(opts)
        return create_function(opts)
    end,
    call_function = function(opts)
        return string.format("%s(%s)", opts.name, table.concat(opts.args, ", "))
    end,
}
return go
