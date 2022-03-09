local php = {
    comment = function(statement)
        return string.format("// %s", statement)
    end,
    print_var = function(opts)
        return string.format(
            "printf('%s %%s'.%s, %s);",
            opts.prefix,
            '"\\n"', -- this feels really ugly..
            opts.var
        )
    end,
    print = function(opts)
        return string.format('printf("%s\\n");', opts.content)
    end,
}
return php
