local Region = require("refactoring.region")
local lsp_utils = require("refactoring.lsp_utils")
local test_utils = require("refactoring.tests.utils")
local ts = require("refactoring.ts")

local function setup()
    vim.cmd(":new")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "foo",
        "if (true) {",
        "    bar",
        "}",
    })
end

describe("lsp_utils", function()
    it("should get the references and definition of cursor", function()
        local bufnr = test_utils.open_test_file("lsp_utils_test_file.ts")

        vim.cmd(":3")
        test_utils.vim_motion("fo")
        assert.are.same(vim.fn.expand("<cWORD>"), "foo")

        local current_node = ts.get_node_at_cursor(0)
        local definition = ts.find_definition(current_node, bufnr)
        local def_region = Region:from_node(definition)
        local references = ts.find_references(definition, nil, bufnr)

        assert.are.same(def_region, Region:from_values(bufnr, 2, 11, 2, 13))
        assert.are.same(#references, 1)
        assert.are.same(
            Region:from_node(references[1]),
            Region:from_values(bufnr, 3, 16, 3, 18)
        )
    end)

    it("should delete text.", function()
        setup()
        test_utils.vim_motion("2jfbviw")
        local region = Region:from_current_selection()
        local delete_text = lsp_utils.delete_text(region)
        vim.lsp.util.apply_text_edits({ delete_text })
        assert.are.same({
            "foo",
            "if (true) {",
            "    ",
            "}",
        }, vim.api.nvim_buf_get_lines(
            0,
            0,
            -1,
            false
        ))
    end)

    -- TODO: Genuinely think that this could be a bug within neovim.  I cannot
    -- set the end col = start col or else it will consume the starting
    -- character
    it("should insert text.", function()
        setup()
        test_utils.vim_motion("2jfbviw")
        local region = Region:from_current_selection()
        local insert_text = lsp_utils.insert_text(region, "hello, piq")
        vim.lsp.util.apply_text_edits({ insert_text })
        assert.are.same({
            "foo",
            "if (true) {",
            "    hello, piqbar",
            "}",
        }, vim.api.nvim_buf_get_lines(
            0,
            0,
            -1,
            false
        ))
    end)

    it("should be able to replace a single part of code.", function()
        setup()
        test_utils.vim_motion("2jfbviw")
        local region = Region:from_current_selection()
        local insert_text, delete_text = lsp_utils.replace_text(
            region,
            [[

baz, buzz,
bin, ban,]]
        )

        vim.lsp.util.apply_text_edits({ insert_text, delete_text })

        assert.are.same({
            "foo",
            "if (true) {",
            "    ",
            "baz, buzz,",
            "bin, ban,",
            "}",
        }, vim.api.nvim_buf_get_lines(
            0,
            0,
            -1,
            false
        ))
    end)
end)
