-- stylua: ignore start
local function simple_function()
    local test = {
        value = 11,
        test_other =  function(self) return self.value end ,
    }
    print(test:test_other())
    -- __AUTO_GENERATED_PRINT_VAR_START__
    print([==[simple_function test:test_other():]==], vim.inspect(test:test_other())) -- __AUTO_GENERATED_PRINT_VAR_END__
end
