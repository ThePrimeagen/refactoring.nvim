local Region = require("refactoring.region")
local Query = require("refactoring.query")
local utils = require("refactoring.utils")
local test_utils = require("refactoring.tests.utils")

local function setup()
    vim.cmd(":new")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "foo",
        "if (true) {",
        "    bar",
        "}",
    })
    local bufnr = vim.api.nvim_get_current_buf()
    local filetype = "typescript"
    vim.bo[bufnr].filetype = filetype
    return bufnr, filetype
end

describe("Utils", function()
    it("table intersection", function()
        local a = {
            foo = 5,
            bar = 69,
            baz = 420,
            buzz = 1337,
        }

        local b = {
            bar = 69,
            baz = 420,
            shoe = 69420,
        }

        assert.are.same({
            bar = 69,
            baz = 420,
        }, utils.table_key_intersect(a, b))
    end)

    it("node intersection & complement", function()
        local bufnr, filetype = setup()
        local query = Query:new(
            bufnr,
            filetype,
            assert(vim.treesitter.query.get(filetype, "locals"))
        )
        local root = Query.get_root(bufnr, filetype)

        test_utils.vim_motion("jjfbviw")
        local region = Region:from_current_selection()
        local captures = query:pluck_by_capture(
            root,
            Query.query_type.Reference
        )
        local intersections = vim.iter(captures):filter(function(node)
            return utils.region_intersect(node, region)
        end):totable()

        assert.are.same(#intersections, 1)
        assert.are.same(vim.treesitter.get_node_text(intersections[1], bufnr), "bar")
        local complements = vim.iter(captures):filter(function(node) return utils.region_complement(node, region) end)
            :totable()

        assert.are.same(#complements, 1)
        assert.are.same(vim.treesitter.get_node_text(complements[1], bufnr), "foo")
    end)
end)
