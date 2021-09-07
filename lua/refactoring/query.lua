local parsers = require("nvim-treesitter.parsers")
local ts_utils = require("nvim-treesitter.ts_utils")
local utils = require("refactoring.utils")

--- local myEnum = Enum {
---     'Foo',          -- Takes value 1
---     'Bar',          -- Takes value 2
---     {'Qux', 10},    -- Takes value 10
---     'Baz',          -- Takes value 11
--- }

-- @class Query2
-- @field query Query
-- @field types Query
-- @field scope tsnode
-- @field region Region
-- @field filter function
-- @field region_calc_type string
local Query = {}
Query.__index = Query

local Query2 = {}
Query2.__index = Query2
function Query2:from_query(query)
    return setmetatable({
        query = query,
    }, self)
end

function Query2:with_types(types)
    self.types = types
    return self
end

function Query2:with_scope(scope)
    self.scope = scope
    return self
end

function Query2:with_intersect(region)
    self.region_calc_type = "intersect"
    self.region = region
    return self
end

function Query2:with_filter(fn)
    self.filter = fn
    return self
end

function Query2:with_complement(region)
    self.region_calc_type = "complement"
    self.region = region
    return self
end

function Query2:get_nodes()
    local root = self.scope or Query.get_root(self.query.bufnr, self.query.filetype)
    local nodes = self.query:pluck_by_capture(root, self.types)

    if self.region then
        nodes = self.region_calc_type == "intersect" and
            utils.region_intersect(nodes, self.region) or
            utils.region_complement(nodes, self.region)
    end

    if self.filter then
        nodes = vim.tbl_filter(self.filter, nodes)
    end

    return nodes
end

Query.query_type = {
    FunctionArgument = "definition.function_argument",
    LocalVarName = "definition.local_name",
    Reference = "reference",
    Statement = "definition.statement",
    Scope = "definition.scope",
    Block = "definition.block",
    Declarator = "definition.local_declarator",
    LocalVarValue = "definition.local_value",
}

function Query.get_root(bufnr, filetype)
    local parser = parsers.get_parser(bufnr or 0, filetype)
    return parser:parse()[1]:root()
end

function Query:new(bufnr, filetype, query)
    return setmetatable({
        query = query,
        bufnr = bufnr,
        filetype = filetype,
        root = Query.get_root(bufnr, filetype),
    }, self)
end

function Query:get_scope_over_region(region, capture_name)
    capture_name = capture_name or Query.query_type.Scope
    local start_row, start_col, end_row, end_col = region:to_ts()
    local start_scope = self:get_scope_by_position(
        start_row,
        start_col,
        capture_name
    )
    local end_scope = self:get_scope_by_position(end_row, end_col, capture_name)

    if start_scope ~= end_scope then
        error("Selection spans over two scopes, cannot determine scope")
    end

    return start_scope
end

function Query:get_scope_by_position(line, col, capture_name)
    capture_name = capture_name or Query.query_type.Scope
    local out = nil
    for id, n, _ in self.query:iter_captures(self.root, self.bufnr, 0, -1) do
        if
            self.query.captures[id] == capture_name
            and ts_utils.is_in_node_range(n, line, col)
            and (out == nil or utils.node_contains(out, n))
        then
            out = n
        end
    end

    return out
end

function Query:pluck_by_capture(scope, captures)
    if type(captures) ~= "table" then
        captures = {captures}
    end

    local out = {}
    for id, node, _ in self.query:iter_captures(scope, self.bufnr, 0, -1) do
        local n_capture = self.query.captures[id]
        for _, capture in pairs(captures) do
            if n_capture == capture then
                table.insert(out, node)
                break
            end
        end
    end
    return out
end

function Query.find_occurrences(scope, sexpr, bufnr)
    local filetype = vim.bo[bufnr].filetype

    -- TODO: Ask tj why my life is terrible
    local sexpr_query = vim.treesitter.parse_query(
        filetype,
        sexpr .. " @tmp_capture"
    )

    local occurances = {}
    for _, n in sexpr_query:iter_captures(scope, bufnr, 0, -1) do
        table.insert(occurances, n)
    end
    return occurances
end

return Query, Query2
