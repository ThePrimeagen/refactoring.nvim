local utils = require("refactoring.code_generation.utils")

local function isClassFunction(scope)
    return scope:type() == "method_declaration"
end

local function go_function(opts)
    if isClassFunction(opts.scope) then
        local text = utils.get_class_name(opts.query, opts.scope)
        return string.format(
            [[
func %s %s(%s) {
    %s
}
]],
            text,
            opts.name,
            table.concat(opts.args, ", "),
            utils.stringify_code(opts.body)
        )
    else
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
end

local function go_call_func(opts)
    if isClassFunction(opts.scope) then
        local type = utils.get_class_type(opts.query, opts.scope)
        return string.format(
            "%s.%s(%s)",
            type,
            opts.name,
            table.concat(opts.args, ", ")
        )
    else
        return string.format("%s(%s)", opts.name, table.concat(opts.args, ", "))
    end
end

local go = {
    constant = function(opts)
        return string.format("%s := %s\n", opts.name, opts.value)
    end,
    ["return"] = function(code)
        return string.format("return %s", utils.stringify_code(code))
    end,
    ["function"] = function(opts)
        return go_function(opts)
    end,
    call_function = function(opts)
        return go_call_func(opts)
    end,

    terminate = function(code)
        return code .. "\n"
    end,
}
return go
