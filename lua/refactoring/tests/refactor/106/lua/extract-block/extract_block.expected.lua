-- stylua: ignore start

local function foo_bar(a)
    local test = 1
    local test_other = 11
    for idx = test - 1, test_other do
        print(idx, a)
    end
end


function simple_function(a)
    foo_bar(a)
end
