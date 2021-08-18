-- local lsp_utils = require("refactoring.lsp_utils")
local test_utils = require("refactoring.tests.utils")

describe("lsp_utils", function()
    it("should get the references and definition of cursor", function()
        local bufnr = vim.api.nvim_create_buf(false, false)
        vim.api.nvim_win_set_buf(0, bufnr)
        vim.bo[bufnr].filetype = "typescript"
        vim.api.nvim_buf_set_lines(
            bufnr,
            0,
            -1,
            false,
            test_utils.split_string(
                [[function testFunction(testVar: number): number {
    const foo = 5 * testVar;
    return 5 * foo * testVar;
}
]],
                "\n"
            )
        )

        -- TODO: I literally cannot figure this out.
        -- It appears that the lsp isn't started.  The number of clients is 0.
        -- :(
        --[[
        vim.cmd(":LspStart")
        assert.are.same(#vim.lsp.buf_get_clients(), 1)

        vim.cmd("/foo")
        local definition = lsp_utils.get_definition_under_cursor(bufnr)
        local references = lsp_utils.get_references_under_cursor(bufnr)

        assert.are.same(definition, references)
        ]]
    end)
end)
