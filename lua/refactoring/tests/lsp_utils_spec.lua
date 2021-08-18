-- local lsp_utils = require("refactoring.lsp_utils")
local test_utils = require("refactoring.tests.utils")

describe("lsp_utils", function()
    it("should get the references and definition of cursor", function()
        -- local bufnr = vim.api.nvim_create_buf(false, false)
        vim.cmd(":e ./lua/refactoring/tests/lsp_utils_test_file.ts")
        --[[
        vim.cmd(":LspStart")
        vim.wait(4000, function()
            return #vim.lsp.buf_get_clients() > 0
        end)
        assert.are.same(#vim.lsp.buf_get_clients(), 1)
        ]]

        vim.cmd(":3")
        test_utils.vim_motion("fo")
        assert.are.same(vim.fn.expand("<cWORD>"), "foo")

        --[[
        local definition = lsp_utils.get_definition_under_cursor(bufnr)
        local references = lsp_utils.get_references_under_cursor(bufnr)

        assert.are.same(definition, references)
        ]]
    end)
end)
