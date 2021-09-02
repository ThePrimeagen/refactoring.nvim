local LspDefinition = require("refactoring.lsp")
local Query = require("refactoring.query")
local test_utils = require("refactoring.tests.utils")

describe("Lsp Definition", function()
    it("should get the name next for the definition.", function()
        vim.cmd(":e ./lua/refactoring/tests/lsp_utils_test_file.ts")

        local bufnr = vim.api.nvim_get_current_buf()
        local filetype = "typescript"
        vim.cmd("LspStart")

        local query = Query:new(
            bufnr,
            filetype,
            vim.treesitter.get_query(filetype, "refactoring")
        )

        test_utils.vim_motion("2jff")

        -- Ensure the lsp has been started
        test_utils.get_definition_under_cursor(bufnr)

        local definition = LspDefinition:from_cursor(bufnr, query)

        assert.are.same(definition:get_value_text(), "5*testVar")
        assert.are.same(definition:get_name_text(), "foo")
    end)
end)
