-- stylua: ignore start
local function simple_function()
    local test = {
        test_other = 11,
    }
    print(test.test_other)
    -- __AUTO_GENERATED_PRINT_VAR_START__
    print([==[simple_function test.test_other:]==], vim.inspect(test.test_other)) -- __AUTO_GENERATED_PRINT_VAR_END__
end
