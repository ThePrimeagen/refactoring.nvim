local TreeSitter = require("refactoring.treesitter")
local Point = require("refactoring.point")
local Nodes = require("refactoring.treesitter.nodes")

-- I know this is inefficient, just makes it feel nice :)
local function get_parent_scope(ts, node, count)
    count = count or 1
    for _ = 1, count do
        node = ts:get_parent_scope(node)
    end
    return node
end

local function set_position(line, col)
    -- vim.cmd(string.format(":call cursor(%d, %d)", line or 0, col or 0))
    vim.api.nvim_win_set_cursor(0, { line or 0, col or 0 })
end

local function get_scope(ts, line, col)
    set_position(line, col)

    -- todo, I forgot how to set the column and I cannot find it currently
    -- within the help docs
    local node = Point:from_cursor():to_ts_node(ts:get_root())
    return get_parent_scope(ts, node, 1)
end

local function get_indent_scope(ts, line, col)
    set_position(line, col)
    local cursor = Point:from_cursor():to_ts_node(ts:get_root())
    return ts:indent_scope(cursor)
end

local function init()
    vim.cmd("e lua/refactoring/tests/treesitter/get_scope.ts")
    return TreeSitter.get_treesitter()
end

-- HACK: pcall with lua class functions are weird, having this as a wrapper
local function ts_valid(ts, setting)
    ts:validate_setting(setting)
end

describe("TreeSitter", function()
    it("should get indent count between two scopes", function()
        local ts = init()
        local indent_scope = get_indent_scope(ts, 39)
        local parent = get_scope(ts, 33)

        local indent_count = ts:indent_scope_difference(parent, indent_scope)
        assert.are.same(indent_count, 2)
    end)

    it("should indent 0 because child == ancestor", function()
        local ts = init()
        local indent_scope = get_indent_scope(ts, 39)

        local indent_count =
            ts:indent_scope_difference(indent_scope, indent_scope)
        assert.are.same(indent_count, 0)
    end)

    it("should throw error because of two different trees.", function()
        local ts = init()
        local indent_scope = get_indent_scope(ts, 39)
        local other_scope = get_indent_scope(ts, 43)

        -- throw error
        local ok = pcall(function()
            ts:indent_scope_difference(indent_scope, other_scope)
        end)
        assert.are.same(ok, false)
    end)

    -- This will be hard since we do not test every
    it("get_scope", function()
        local ts = init()

        local scope = get_scope(ts, 3)
        assert.are.same("class_declaration", scope:type())
        assert.are.same("program", get_parent_scope(ts, scope):type())

        scope = get_scope(ts, 5)
        assert.are.same(5, vim.fn.line("."))
        assert.are.same("method_definition", scope:type())
        assert.are.same("class_declaration", get_parent_scope(ts, scope):type())
        assert.are.same("program", get_parent_scope(ts, scope, 2):type())

        scope = get_scope(ts, 15)
        assert.are.same(15, vim.fn.line("."))
        assert.are.same("method_definition", scope:type())
        assert.are.same(
            "class_declaration",
            get_parent_scope(ts, scope, 1):type()
        )
        assert.are.same(
            "function_declaration",
            get_parent_scope(ts, scope, 2):type()
        )
        assert.are.same("arrow_function", get_parent_scope(ts, scope, 3):type())
        assert.are.same("program", get_parent_scope(ts, scope, 4):type())
    end)

    it("should get function's local vars", function()
        local ts = init()

        local scope = get_scope(ts, 33)
        local local_vars = ts:get_local_declarations(scope)

        assert.are.same(#local_vars, 2)
        local cur_bufnr = vim.api.nvim_get_current_buf()
        assert.are.same(
            "let foo = 5;",
            vim.treesitter.get_node_text(local_vars[1], cur_bufnr)
        )
        assert.are.same(
            "const bar = 5;",
            vim.treesitter.get_node_text(local_vars[2], cur_bufnr)
        )
    end)

    it("get declaration under cursor", function()
        local ts = init()

        set_position(33, 10)
        local node = ts:local_declarations_under_cursor()

        assert.are.same(
            "const bar = 5;",
            vim.treesitter.get_node_text(node, vim.api.nvim_get_current_buf())
        )
    end)

    it("Inline Node basic test root scope", function()
        local ts = init()
        local scope = ts:get_root()
        local inline_node = Nodes.InlineNode("(return_statement) @tmp_capture")
        local bufnr = vim.api.nvim_get_current_buf()
        local inline_node_result = inline_node(scope, bufnr, ts.filetype)
        assert.are.same(#inline_node_result, 4)
        local cur_bufnr = vim.api.nvim_get_current_buf()
        assert.are.same(
            "return test;",
            vim.treesitter.get_node_text(inline_node_result[1], cur_bufnr)
        )
        assert.are.same(
            "return 5;",
            vim.treesitter.get_node_text(inline_node_result[2], cur_bufnr)
        )
        assert.are.same(
            "return 5;",
            vim.treesitter.get_node_text(inline_node_result[3], cur_bufnr)
        )
        assert.are.same(
            "return inner() * foo * bar;",
            vim.treesitter.get_node_text(inline_node_result[4], cur_bufnr)
        )
    end)

    it("Inline Node in scope not root", function()
        local ts = init()
        local scope = get_scope(ts, 31)
        local inline_node = Nodes.InlineNode("(return_statement) @tmp_capture")
        local bufnr = vim.api.nvim_get_current_buf()
        local inline_node_result = inline_node(scope, bufnr, ts.filetype)
        assert.are.same(#inline_node_result, 2)

        local cur_bufnr = vim.api.nvim_get_current_buf()
        assert.are.same(
            "return 5;",
            vim.treesitter.get_node_text(inline_node_result[1], cur_bufnr)
        )
        assert.are.same(
            "return inner() * foo * bar;",
            vim.treesitter.get_node_text(inline_node_result[2], cur_bufnr)
        )
    end)

    it("Inline Node tests with Treesitter statements", function()
        local ts = init()
        local scope = get_scope(ts, 31)
        local inline_node_result = ts:get_statements(scope)
        assert.are.same(#inline_node_result, 9)

        local cur_bufnr = vim.api.nvim_get_current_buf()
        assert.are.same(
            "return 5;",
            vim.treesitter.get_node_text(inline_node_result[1], cur_bufnr)
        )
        assert.are.same(
            "return inner() * foo * bar;",
            vim.treesitter.get_node_text(inline_node_result[2], cur_bufnr)
        )
        assert.are.same(
            "if (true) {\n            let fazz = 7;\n        }",
            vim.treesitter.get_node_text(inline_node_result[3], cur_bufnr)
        )
        assert.are.same(
            "if (true) {\n            let buzzzbaszz = 69;\n        }",
            vim.treesitter.get_node_text(inline_node_result[4], cur_bufnr)
        )
        assert.are.same(
            "let foo = 5;",
            vim.treesitter.get_node_text(inline_node_result[5], cur_bufnr)
        )
        assert.are.same(
            "const bar = 5;",
            vim.treesitter.get_node_text(inline_node_result[6], cur_bufnr)
        )
        assert.are.same(
            "let baz = 5;",
            vim.treesitter.get_node_text(inline_node_result[7], cur_bufnr)
        )
        assert.are.same(
            "let fazz = 7;",
            vim.treesitter.get_node_text(inline_node_result[8], cur_bufnr)
        )
        assert.are.same(
            "let buzzzbaszz = 69;",
            vim.treesitter.get_node_text(inline_node_result[9], cur_bufnr)
        )
    end)

    it("Inline Node Tests Failing query", function()
        local ts = init()
        local scope = get_scope(ts, 3)
        local failingInlineNode = Nodes.InlineNode("This should fail")

        local status, err =
            pcall(failingInlineNode, scope, ts.bufnr, ts.filetype)
        assert.are.same(false, status)
        local user_error = string.find(err, "Invalid query: 'This should fail'")
        assert(user_error ~= nil)
        local query_error =
            string.find(err, "Query error at 1:1. Invalid syntax")
        assert(query_error ~= nil)
    end)

    it("Query Node Failure query", function()
        local ts = init()
        local scope = get_scope(ts, 3)
        local failingQueryNode = Nodes.QueryNode("This should fail")

        local status, err =
            pcall(failingQueryNode, scope, ts.bufnr, ts.filetype)
        assert.are.same(false, status)
        local user_error =
            string.find(err, "Invalid query: 'This should fail @tmp_capture'")
        assert(user_error ~= nil)
        local query_error =
            string.find(err, "Query error at 1:1. Invalid syntax")
        assert(query_error ~= nil)
    end)

    it("Validate setting is on treesitter success", function()
        local ts = init()

        local status, err = pcall(ts_valid, ts, "scope_names")
        assert(status == true)
        assert(err == nil)
    end)

    it("Validate setting is empty on treesitter", function()
        local ts = init()
        local setting = "thisShouldFail"
        ts[setting] = {}

        local status, err = pcall(ts_valid, ts, setting)

        assert(status == false)
        local query_error = string.find(
            err,
            string.format(
                "%s setting is empty in treesitter for this language",
                setting
            )
        )
        assert(query_error ~= nil)
    end)

    it("Validate setting is does not exist on treesitter", function()
        local ts = init()
        local setting = "doesNotExist"

        local status, err = pcall(ts_valid, ts, setting)

        assert(status == false)
        local query_error = string.find(
            err,
            string.format(
                "%s setting does not exist on treesitter class",
                setting
            )
        )
        assert(query_error ~= nil)
    end)
end)
