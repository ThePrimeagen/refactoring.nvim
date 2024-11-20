local ts = require("refactoring.code_generation.langs.typescript")

---@type code_generation
local vue = {
    default_printf_statement = ts.default_printf_statement,
    print = ts.print,
    default_print_var_statement = ts.default_print_var_statement,
    print_var = ts.print_var,
    comment = ts.comment,
    constant = ts.constant,
    special_var = ts.special_var,
    pack = ts.pack,

    unpack = ts.unpack,

    ["return"] = ts["return"],
    ["function"] = ts["function"],
    function_return = ts.function_return,
    call_function = ts.call_class_function,
    terminate = ts.terminate,
    class_function = ts.class_function,

    class_function_return = ts.class_function_return,

    call_class_function = ts.call_class_function,
}

return vue
