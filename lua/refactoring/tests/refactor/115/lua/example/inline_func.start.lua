-- stylua: ignore start

local function foo_bar(a, test)
    local test_other = 11
    for idx = test - 1, test_other do
        print(idx, a)
    end
    return test_other
end


function simple_function(a)
    local test = 1
    local test_other = foo_bar(a, test)


    return test, test_other
end
