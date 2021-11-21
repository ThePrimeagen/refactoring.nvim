-- stylua: ignore start

function simple_function(a)
    local test = 1
    local test_other = 11
print(string.format("simple_function test_other: %s", test_other))
    for idx = test - 1, test_other do
        print(idx, a)
    end
end
