-- stylua: ignore start

function simple_function(a)
    local test = 1
    local test_other = 11
print("simple_function test_other:", test_other)
    for idx = test - 1, test_other do
        print(idx, a)
    end
end
