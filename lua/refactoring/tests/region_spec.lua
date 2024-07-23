local Region = require("refactoring.region")
local eq = assert.are.same
local vim_motion = require("refactoring.tests.utils").vim_motion

local function setup()
    vim.cmd(":new")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "foo",
        "if (true) {",
        "    bar",
        "이미지가 서버에 저장되었습니다",
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

        vim_motion("jwvww")
        local region = Region:from_current_selection()
        eq({ "(true)" }, region:get_text())
    end)

    it("select text : multibyte-partial-line", function()
        setup()

        vim.cmd(":1")
        vim_motion("jwvje")
        eq("n", vim.api.nvim_get_mode().mode)
        eq(3, vim.fn.line("."))
        local region = Region:from_current_selection()
        eq({ "(true) {", "    bar" }, region:get_text())
    end)

    it("select text : multi-partial-line", function()
        setup()

        vim.cmd(":4")
        vim_motion("viw")
        eq("n", vim.api.nvim_get_mode().mode)
        eq(4, vim.fn.line("."))
        local region = Region:from_current_selection()
        eq({ "이미지가" }, region:get_text())
    end)

    it("contain region", function()
        local region = Region:from_values(0, 10, 100, 12, 50)
        local ins = {
            Region:from_values(0, 11, 0, 11, 69),
            Region:from_values(0, 10, 100, 12, 50),
            Region:from_values(0, 10, 100, 10, 10000),
        }

        local outs = {
            Region:from_values(0, 9, 100, 12, 50), -- out on start row
            Region:from_values(0, 10, 99, 11, 69), -- out on start col
            Region:from_values(0, 11, 100, 13, 50), -- out on end row
            Region:from_values(0, 11, 51, 12, 51), -- out on end col
            Region:from_values(1, 11, 51, 11, 52), -- diff bufnr
        }

        for _, v in pairs(ins) do
            eq(true, region:contains(v))
        end

        for _, v in pairs(outs) do
            eq(false, region:contains(v))
        end
    end)

    it("is empty", function()
        local region = Region:from_values(0, 0, 0, 0, 0)
        eq(true, region:is_empty())
        region = Region:from_values(0, 1, 0, 0, 0)
        eq(false, region:is_empty())
        region = Region:from_values(0, 0, 1, 0, 0)
        eq(false, region:is_empty())
        region = Region:from_values(0, 0, 0, 1, 0)
        eq(false, region:is_empty())
        region = Region:from_values(0, 0, 0, 0, 1)
        eq(false, region:is_empty())
    end)
end)
