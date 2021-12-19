local ts_utils = require("nvim-treesitter.ts_utils")
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

        local indent_count = ts:indent_scope_difference(
            indent_scope,
            indent_scope
        )
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
        local local_vars = ts:local_declarations(scope)

        assert.are.same(#local_vars, 2)
        assert.are.same(
            "let foo = 5;",
            ts_utils.get_node_text(local_vars[1])[1]
        )
        assert.are.same(
            "const bar = 5;",
            ts_utils.get_node_text(local_vars[2])[1]
        )
    end)

    it("get declaration under cursor", function()
        local ts = init()

        set_position(33, 10)
        local node = ts:local_declarations_under_cursor()

        assert.are.same("const bar = 5;", ts_utils.get_node_text(node)[1])
    end)

    it("Inline Node basic test root scope", function()
        local ts = init()
        local scope = ts:get_root()
        local inline_node = Nodes.InlineNode("(return_statement) @tmp_capture")
        local bufnr = vim.api.nvim_get_current_buf()
        local inline_node_result = inline_node(scope, bufnr, ts.filetype)
        assert.are.same(#inline_node_result, 4)
        assert.are.same(
            "return test;",
            ts_utils.get_node_text(inline_node_result[1])[1]
        )
        assert.are.same(
            "return 5;",
            ts_utils.get_node_text(inline_node_result[2])[1]
        )
        assert.are.same(
            "return 5;",
            ts_utils.get_node_text(inline_node_result[3])[1]
        )
        assert.are.same(
            "return inner() * foo * bar;",
            ts_utils.get_node_text(inline_node_result[4])[1]
        )
    end)

    it("Inline Node in scope not root", function()
        local ts = init()
        local scope = get_scope(ts, 31)
        local inline_node = Nodes.InlineNode("(return_statement) @tmp_capture")
        local bufnr = vim.api.nvim_get_current_buf()
        local inline_node_result = inline_node(scope, bufnr, ts.filetype)
        assert.are.same(#inline_node_result, 2)
        assert.are.same(
            "return 5;",
            ts_utils.get_node_text(inline_node_result[1])[1]
        )
        assert.are.same(
            "return inner() * foo * bar;",
            ts_utils.get_node_text(inline_node_result[2])[1]
        )
    end)

    it("Inline Node tests with Treesitter statements", function()
        local ts = init()
        local scope = get_scope(ts, 31)
        local inline_node_result = ts:get_statements(scope)
        assert.are.same(#inline_node_result, 9)
        assert.are.same(
            "return 5;",
            ts_utils.get_node_text(inline_node_result[1])[1]
        )
        assert.are.same(
            "return inner() * foo * bar;",
            ts_utils.get_node_text(inline_node_result[2])[1]
        )
        assert.are.same(
            "if (true) {",
            ts_utils.get_node_text(inline_node_result[3])[1]
        )
        assert.are.same(
            "if (true) {",
            ts_utils.get_node_text(inline_node_result[4])[1]
        )
        assert.are.same(
            "let foo = 5;",
            ts_utils.get_node_text(inline_node_result[5])[1]
        )
        assert.are.same(
            "const bar = 5;",
            ts_utils.get_node_text(inline_node_result[6])[1]
        )
        assert.are.same(
            "let baz = 5;",
            ts_utils.get_node_text(inline_node_result[7])[1]
        )
        assert.are.same(
            "let fazz = 7;",
            ts_utils.get_node_text(inline_node_result[8])[1]
        )
        assert.are.same(
            "let buzzzbaszz = 69;",
            ts_utils.get_node_text(inline_node_result[9])[1]
        )
    end)
end)
