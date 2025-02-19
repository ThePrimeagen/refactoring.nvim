-- stylua: ignore start
local function simple_function()
    local test = {
        value = 11,
        test_other =  function(self) return self.value end ,
    }
    print(test:test_other())
end
