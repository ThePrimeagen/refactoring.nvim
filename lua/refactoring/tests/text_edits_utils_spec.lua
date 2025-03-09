local Region = require("refactoring.region")
local text_edits_utils = require("refactoring.text_edits_utils")
local test_utils = require("refactoring.tests.utils")
local ts_locals = require("refactoring.ts-locals")
---@module 'luassert'

local function setup()
    vim.cmd(":new")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "foo",
        "if (true) {",
        "    bar",
        "}",
    })

    local co = coroutine.running()
    _G.operatorfunc = function(type)
        local region_type = type == "line" and "V"
            or type == "char" and "v"
            or type == "block" and ""
            or nil
        coroutine.resume(co, Region:from_motion({ type = region_type }))
    end
    vim.o.operatorfunc = "v:lua.operatorfunc"
end

describe("text_edits_utils", function()
    it("should get the references and definition of cursor", function()
        local bufnr = test_utils.open_test_file("text_edits_utils_test_file.ts")

        vim.cmd(":3")
        test_utils.vim_motion("fo")
        assert.are.same(vim.fn.expand("<cWORD>"), "foo")

        local parser = vim.treesitter.get_parser()
        parser:parse()

        local current_node = vim.treesitter.get_node()
        assert.no.is_nil(current_node) ---@cast current_node -nil
        local definition = ts_locals.find_definition(current_node, bufnr)
        local def_region = Region:from_node(definition)
        local references = ts_locals.find_usages(definition, nil, bufnr)

        assert.are.same(def_region, Region:from_values(bufnr, 2, 11, 2, 13))
        assert.are.same(#references, 1)
        assert.are.same(
            Region:from_node(references[1]),
            Region:from_values(bufnr, 3, 16, 3, 18)
        )
    end)

    it("should delete text.", function()
        setup()
        vim.schedule(function()
            test_utils.vim_motion("2jfbviwg@")
        end)
        local region = coroutine.yield()
        local delete_text = text_edits_utils.delete_text(region)
        local bufnr = vim.api.nvim_get_current_buf()
        vim.lsp.util.apply_text_edits({ delete_text }, bufnr, "utf-16")
        assert.are.same({
            "foo",
            "if (true) {",
            "    ",
            "}",
        }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
    end)

    it("should insert text.", function()
        setup()
        vim.schedule(function()
            test_utils.vim_motion("2jfbviwg@")
        end)
        local region = coroutine.yield()
        local insert_text = text_edits_utils.insert_text(region, "hello, piq")
        local bufnr = vim.api.nvim_get_current_buf()
        vim.lsp.util.apply_text_edits({ insert_text }, bufnr, "utf-16")
        assert.are.same({
            "foo",
            "if (true) {",
            "    hello, piqbar",
            "}",
        }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
    end)

    it("should be able to replace a single part of code.", function()
        setup()
        vim.schedule(function()
            test_utils.vim_motion("2jfbviwg@")
        end)
        local region = coroutine.yield()
        local insert_text = text_edits_utils.replace_text(
            region,
            [[

baz, buzz,
bin, ban,]]
        )

        local bufnr = vim.api.nvim_get_current_buf()
        vim.lsp.util.apply_text_edits({ insert_text }, bufnr, "utf-16")

        assert.are.same({
            "foo",
            "if (true) {",
            "    ",
            "baz, buzz,",
            "bin, ban,",
            "}",
        }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
    end)
end)
