local ts_utils = require("nvim-treesitter.ts_utils")
local ts_query = require("nvim-treesitter.query")
local parsers = require("nvim-treesitter.parsers")
local locals = require("nvim-treesitter.locals")

local M = {}

M.get_root = function(lang)
    local parser = parsers.get_parser(0, lang)
    return parser:parse()[1]:root()
end

-- determines if a contains node b.
-- @param a the containing node
-- @param b the node to be contained
function M.node_contains(a, b)
    if a == nil or b == nil then
        return false
    end

    local start_row, start_col, end_row, end_col = b:range()
    return ts_utils.is_in_node_range(a, start_row, start_col)
        and ts_utils.is_in_node_range(a, end_row, end_col)
end

-- determines if a node exists within a range.  Imagine a range selection
-- across '<,'> and an identifier.  Does the identifier exist within the
-- selection?
--
M.range_contains_node = function(node, start_row, start_col, end_row, end_col)
    local node_start_row, node_start_col, node_end_row, node_end_col =
        node:range()

    -- There are five possible conditions
    -- 1. node start/end row are contained exclusively within the range.
    -- 2. The range is a single line range
    --   - the node start/end row must equal start_row and cols have to exist
    --     within range, inclusive
    -- 3. The node exists solely within the first line
    --   - node_start_col has to be inclusive with start_col, end col doesn't
    --     matter.
    -- 4. The node exists solely within the last line
    --   - node_start_col doesn't matter whereas node_end_col has to be
    --     inclusive with end_col
    -- 5. The node starts / ends on the same rows and has to have each column
    --    considered
    if start_row < node_start_row and end_row > node_end_row then
        return true
    elseif start_row == end_row then
        return start_row == node_start_row
            and end_row == node_end_row
            and start_col <= node_start_col
            and end_col >= node_end_col
    elseif start_row == node_start_row and start_row == node_end_row then
        return start_col <= node_start_col
    elseif end_row == node_start_row and end_row == node_end_row then
        return end_col >= node_end_col
    elseif start_row <= node_start_row and end_row >= node_end_row then
        return start_col <= node_start_col and end_col >= node_end_col
    end

    return false
end

-- param region Region
M.get_scope_over_selection = function(root, region, lang)
    local start_row, start_col, end_row, end_col = region:to_ts()
    local start_scope = M.get_scope(root, start_row, start_col, lang)
    local end_scope = M.get_scope(root, end_row, end_col, lang)

    if start_scope ~= end_scope then
        error("Selection spans over two scopes, cannot determine scope")
    end

    return start_scope
end

M.get_scope = function(root, line, col, lang)
    -- TODO: Cache them queries boy -- but maybe not?
    local query = vim.treesitter.get_query(lang, "refactoring")

    local out = nil
    for _, n, _ in query:iter_captures(root, 0, 0, -1) do
        if
            ts_utils.is_in_node_range(n, line, col)
            and (out == nil or M.node_contains(out, n))
        then
            out = n
        end
    end

    return out
end

local function get_refactoring_query(lang)
    local query = vim.treesitter.get_query(lang, "refactoring")
    if not query then
        error(
            "refactoring not supported in this language.  Please provide a queries/<lang>/refactoring.scm"
        )
    end
    return query
end

local function pluck_by_capture(scope, lang, query, capture_name)
    local local_defs = {}
    local root = M.get_root(lang)
    for id, node, _ in query:iter_captures(root, 0, 0, -1) do
        if
            query.captures[id] == capture_name
            and M.node_contains(scope, node)
        then
            table.insert(local_defs, node)
        end
    end

    return local_defs
end

M.get_function_args = function(scope, lang)
    return pluck_by_capture(
        scope,
        lang,
        get_refactoring_query(lang),
        "definition.function_argument"
    )
end

M.get_locals_defs = function(scope, lang)
    return pluck_by_capture(
        scope,
        lang,
        get_refactoring_query(lang),
        "definition.local_var"
    )
end

M.get_all_identifiers = function(scope, lang)
    return pluck_by_capture(
        scope,
        lang,
        vim.treesitter.get_query(lang, "locals"),
        "reference"
    )
end

-- is there a better way?
M.range_to_table = function(node)
    if node == nil then
        return "range nil"
    end
    local a, b, c, d = node:range()
    return { a, b, c, d }
end

return M
