-- stylua: ignore start

function simple_function(a)
    local test = 1
    local test_other = 11
    for idx = test - 1, test_other do
        print(idx, a)
    end

    for idx = test - 1, test_other do
        print(idx, test)
    end

    for idx = test - 1, test_other do
        print(idx, a)
    end
end
