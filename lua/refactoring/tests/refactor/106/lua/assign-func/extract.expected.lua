-- stylua: ignore start

local test = {}

local function foobar()
    local a = "hello"
    local b = "test"
    print("a:", a)
    print("b:", b)
end


--- This is a comment
test.configs = function()
    foobar()
end
