-- stylua: ignore start

local function foo_bar(a, x, y)
    print(a, x, y)
end


function simple_function(a)
    local test = {1, 2}
    for x, y in pairs(test) do
        foo_bar(a, x, y)
    end
end
