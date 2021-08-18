local Region = require("refactoring.region")
local eq = assert.are.same
local vim_motion = require("refactoring.tests.utils").vim_motion

local function setup()
    vim.cmd(":new")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "foo",
        "if (true) {",
        "    bar",
        "}",
    })
end

describe("Region", function()
    it("select text : line", function()
        setup()

        vim_motion("jV")
        local region = Region:from_current_selection()
        eq(region:get_text(), { "if (true) {" })
    end)

    it("select text : partial-line", function()
        setup()

        -- TODO: Why is first selection just not present...
        vim_motion("jwvww")
        local region = Region:from_current_selection()
        eq({ "(true)" }, region:get_text())
    end)

    it("select text : multi-partial-line", function()
        setup()

        -- TODO: Why is first selection just not present...
        vim.cmd(":1")
        vim_motion("jwvje")
        eq("n", vim.fn.mode())
        eq(3, vim.fn.line("."))
        local region = Region:from_current_selection()
        eq({ "(true) {", "    bar" }, region:get_text())
    end)
end)
