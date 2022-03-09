local php = {
    comment = function(statement)
        return string.format("// %s", statement)
    end,
    default_print_var_statement = function()
        return { "printf('%s %%s'.%s, %s);" }
    end,
    print_var = function(opts)
        return string.format(
            opts.statement,
            opts.prefix,
            '"\\n"', -- this feels really ugly..
            opts.var
        )
    end,
    default_printf_statement = function()
        return { 'printf("%s\\n");' }
    end,
    print = function(opts)
        return string.format(opts.statement, opts.content)
    end,
}
return php
