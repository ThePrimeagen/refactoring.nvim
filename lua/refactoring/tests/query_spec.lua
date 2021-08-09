local Query = require("refactoring.query")
local Region = require("refactoring.region")
local test_utils = require("refactoring.tests.utils")
local utils = require("refactoring.utils")
local eq = assert.are.same

describe("Query", function()
    it("should capture sexpr", function()
        vim.cmd(":new")
        vim.cmd(":set filetype=typescript")
        local bufnr = vim.fn.bufnr()
        local file = test_utils.read_file("query.ts")
        vim.api.nvim_buf_set_lines(
            0,
            0,
            -1,
            false,
            test_utils.split_string(file, "\n")
        )

        local root = Query.get_root()

        vim.cmd(":14")
        test_utils.vim_motion("fovt-h")

        local query = Query:new(
            0,
            "typescript",
            vim.treesitter.get_query("typescript", "refactoring")
        )
        local region = Region:from_current_selection()
        local extract_node = root:named_descendant_for_range(region:to_ts())
        local scope = query:get_scope_over_region(region)

        local occurrences = Query.find_occurrences(
            scope,
            extract_node:sexpr(),
            bufnr
        )
        eq(3, #occurrences)

        local query_parts = {
            "order",
            ".",
            "quantity",
            "*",
            "order",
            ".",
            "itemPrice",
        }
        eq(query_parts, utils.get_node_text(occurrences[1]))
        eq(query_parts, utils.get_node_text(occurrences[2]))
        eq(query_parts, utils.get_node_text(occurrences[3]))
    end)
end)
