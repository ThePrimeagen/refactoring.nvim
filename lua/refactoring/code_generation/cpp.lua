local cpp = {
    print = function(statement)
        return string.format('printf("%s");', statement)
    end,
}

return cpp

