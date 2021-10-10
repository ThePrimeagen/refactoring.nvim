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

local function get_scope(ts, line, col)
    line = line or 0
    col = col or 0
    vim.cmd(string.format(":call cursor(%d, %d)", line, col))

    -- todo, I forgot how to set the column and I cannot find it currently
    -- within the help docs
    local node = Point:from_cursor():to_ts_node(ts:get_root())
    return get_parent_scope(ts, node, 1)
end

describe("Typescript", function()
    -- This will be hard since we do not test every
    it("get_scope", function()
        vim.cmd("e lua/refactoring/tests/treesitter/get_scope.ts")
        local ts = TreeSitter.get_treesitter()

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
end)
