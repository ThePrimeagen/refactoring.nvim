
local function foo_bar(a, test, test_other)
    for idx = test - 1, test_other do
        print(idx, a)
    end
end


function simple_function(a)
    local test = 1
    local test_other = 11
    foo_bar(a, test, test_other)

    for idx = test - 1, test_other do
        print(idx, test)
    end

    foo_bar(a, test, test_other)
end
