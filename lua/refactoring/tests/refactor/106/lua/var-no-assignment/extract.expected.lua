-- stylua: ignore start

local function foo_bar(a, test, test_other)
    for idx = 0, test_other do
        print(idx, a, test)
    end
end


function simple_function(a)
    local test
    local test_other = 11
    foo_bar(a, test, test_other)
end
