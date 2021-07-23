vim.cmd("set rtp+=" .. vim.loop.cwd())

local eq = assert.are.same

describe("Refactoring", function()
    it("should test selection grabbing", function()
        vim.cmd(":new")
        vim.bo.filetype = "lua"
        vim.api.nvim_buf_set_lines(0, 0, 3, false, {
            "local foo = 5",
            "",
            "foo = foo + 5 + foo",
        })

        eq(3, #vim.api.nvim_buf_get_lines(0, 0, 3, false))
        vim.cmd(":norm! ggVjj<ESC>")
        eq(1, vim.fn.col("'<"), "Selections start at 0")
        eq(#"foo = foo + 5 + foo" + 1, vim.fn.col("'>"), "Selection stops + 1 after last line.")

        -- print("COL", vim.fn.col("'<"), vim.fn.col("'>"))
    end)
end)
