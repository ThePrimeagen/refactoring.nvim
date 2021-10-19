local ts_utils = require("nvim-treesitter.ts_utils")
local TreeSitter = require("refactoring.treesitter")
local Point = require("refactoring.point")

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

local function init()
    vim.cmd("e lua/refactoring/tests/treesitter/get_scope.ts")
    return TreeSitter.get_treesitter()
end

describe("Typescript", function()
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
end)
