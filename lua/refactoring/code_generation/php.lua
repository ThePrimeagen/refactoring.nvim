local php = {
    comment = function(statement)
        return string.format("// %s", statement)
    end,
    print_var = function(prefix, var)
        return string.format(
            "printf('%s %%s'.%s, %s);",
            prefix,
            '"\\n"', -- this feels really ugly..
            var
        )
    end,
    print = function(statement)
        return string.format('printf("%s\\n");', statement)
    end,
}
return php
