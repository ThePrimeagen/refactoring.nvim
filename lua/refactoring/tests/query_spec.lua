local TreeSitter = require("refactoring.treesitter")
local Query = require("refactoring.query")
local Region = require("refactoring.region")
local test_utils = require("refactoring.tests.utils")
local utils = require("refactoring.utils")
local eq = assert.are.same

describe("Query", function()
    it("should capture sexpr", function()
        vim.cmd(":new")
        vim.cmd(":set filetype=typescript")
        local bufnr = vim.api.nvim_get_current_buf()
        local file = test_utils.read_file("query.ts")
        vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(file, "\n"))

        local co = coroutine.running()
        _G.operatorfunc = function(type)
            local region_type = type == "line" and "V"
                or type == "char" and "v"
                or type == "block" and ""
                or nil
            coroutine.resume(co, Region:from_motion({ type = region_type }))
        end
        vim.o.operatorfunc = "v:lua.operatorfunc"

        vim.cmd(":14")
        vim.schedule(function()
            test_utils.vim_motion("fovt-hg@")
        end)

        local region = coroutine.yield()
        local ts = TreeSitter.get_treesitter()
        local extract_node = assert(region:to_ts_node(ts:get_root()))
        local scope = assert(ts:get_scope(extract_node))

        local occurrences =
            Query.find_occurrences(scope, extract_node:sexpr(), bufnr)
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
