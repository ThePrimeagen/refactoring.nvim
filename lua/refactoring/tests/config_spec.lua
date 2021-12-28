local Config = require("refactoring.config")

describe("Config", function()
    it("Check default config prompt func return type ", function()
        local config = Config.get()
        -- Checking those that are in map
        assert.are.same(false, config:get_prompt_func_return_type("go"))
        assert.are.same(false, config:get_prompt_func_return_type("cpp"))
        assert.are.same(false, config:get_prompt_func_return_type("c"))
        assert.are.same(false, config:get_prompt_func_return_type("h"))
        assert.are.same(false, config:get_prompt_func_return_type("hpp"))
        assert.are.same(false, config:get_prompt_func_return_type("cxx"))

        -- Checking those that aren't in map
        assert.are.same(false, config:get_prompt_func_return_type("ts"))
        assert.are.same(false, config:get_prompt_func_return_type("lua"))
    end)
end)

describe("Config", function()
    it("Check setting config prompt ", function()
        local config = Config.get()
        config:set_prompt_func_return_type({ go = true, cpp = true })
        assert.are.same(true, config:get_prompt_func_return_type("go"))
        assert.are.same(true, config:get_prompt_func_return_type("cpp"))
        assert.are.same(false, config:get_prompt_func_return_type("hpp"))
        assert.are.same(false, config:get_prompt_func_return_type("h"))
    end)
end)
