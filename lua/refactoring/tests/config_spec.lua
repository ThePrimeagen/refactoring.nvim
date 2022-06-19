local Config = require("refactoring.config")

describe("Config settings", function()
    it("Check default config prompt func return type ", function()
        local config = Config.get()
        config:reset()
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

    it("Check setting config prompt func return type", function()
        local config = Config.get()
        config:reset()
        config:set_prompt_func_return_type({ go = true, cpp = true })
        assert.are.same(true, config:get_prompt_func_return_type("go"))
        assert.are.same(true, config:get_prompt_func_return_type("cpp"))
        assert.are.same(false, config:get_prompt_func_return_type("hpp"))
        assert.are.same(false, config:get_prompt_func_return_type("h"))
    end)

    it("Check default config prompt func param type", function()
        local config = Config.get()
        config:reset()
        -- Checking those that are in map
        assert.are.same(false, config:get_prompt_func_param_type("go"))

        -- Checking those that aren't in map
        assert.are.same(false, config:get_prompt_func_param_type("ts"))
    end)

    it("Check setting config prompt func param type", function()
        local config = Config.get()
        config:reset()
        config:set_prompt_func_param_type({ go = true })
        assert.are.same(true, config:get_prompt_func_param_type("go"))
        assert.are.same(false, config:get_prompt_func_param_type("ts"))
    end)

    it("Check default config print var normal mode", function()
        local config = Config.get()
        config:reset()
        assert.are.same(false, config:print_var_normal_mode())
    end)

    it("Check setting config print_var_normal_mode", function()
        local config = Config.get()
        config:reset()
        config:set_print_var_normal_mode(true)
        assert.are.same(true, config:print_var_normal_mode())
    end)
end)
