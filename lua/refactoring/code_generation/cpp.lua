local cpp = {
    print = function(statement)
        return string.format('printf("%s \\n");', statement)
    end,
}

return cpp
