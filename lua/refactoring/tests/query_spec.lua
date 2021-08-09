local Query = require("refactoring.query")
local Region = require("refactoring.region")
local test_utils = require("refactoring.tests.utils")
local utils = require("refactoring.utils")
local ts_utils = require("nvim-treesitter.ts_utils")
local eq = assert.are.same

describe("Query", function()
    it("should capture sexpr", function()
        vim.cmd(":new")
        vim.cmd(":set filetype=typescript")
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

        local occurances = query:find_occurances(scope, extract_node:sexpr())
        eq(3, #occurances)
        eq(
            { "order.quantity", "*", "order.itemPrice" },
            utils.trim(ts_utils.get_node_text(occurances[1]))
        )
        eq(
            { "order.quantity * order.itemPrice" },
            utils.trim(ts_utils.get_node_text(occurances[2]))
        )
        eq(
            { "order.quantity *", "order.itemPrice" },
            utils.trim(ts_utils.get_node_text(occurances[3]))
        )
    end)
end)
