-- stylua: ignore start




function simple_function(a)
    local test = 1
    local test_other = 11
    for idx = test - 1, test_other do
        print(idx, a)
    end
    local test_other = test_other


    return test, test_other
end
