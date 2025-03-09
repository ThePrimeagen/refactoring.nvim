local function simple_function()
    local test = {
        test_other = 11,
    }
    print(test.test_other)
    -- __AUTO_GENERATED_PRINT_VAR_START__
    print([==[simple_function test:]==], vim.inspect(test)) -- __AUTO_GENERATED_PRINT_VAR_END__
end
