local LspDefinition = require("refactoring.lsp")
local Query = require("refactoring.query")
local test_utils = require("refactoring.tests.utils")

describe("Lsp Definition", function()
    it("should get the name next for the definition.", function()
        local bufnr = test_utils.open_test_file("lsp_utils_test_file.ts")
        test_utils.start_lsp(bufnr)

        assert.are.same(#vim.lsp.buf_get_clients(bufnr), 1)
        assert.are.same(vim.lsp.buf_is_attached(bufnr, 1), true)

        local filetype = "typescript"
        local query = Query:new(
            bufnr,
            filetype,
            vim.treesitter.get_query(filetype, "refactoring")
        )
        test_utils.vim_motion("2jff")
        local definition = LspDefinition:from_cursor(bufnr, query)

        assert.are.same(definition:get_value_text(), "5*testVar")
        assert.are.same(definition:get_name_text(), "foo")
    end)
end)
