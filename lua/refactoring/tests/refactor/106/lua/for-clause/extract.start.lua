-- stylua: ignore start

function simple_function(a)
    local test = {1, 2}
    for x, y in pairs(test) do
        print(a, x, y)
    end
end
