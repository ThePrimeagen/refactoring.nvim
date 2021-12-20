local parsers = require("nvim-treesitter.parsers")

--- local myEnum = Enum {
---     'Foo',          -- Takes value 1
---     'Bar',          -- Takes value 2
---     {'Qux', 10},    -- Takes value 10
---     'Baz',          -- Takes value 11
--- }

---@class RefactorQuery
local Query = {}
Query.__index = Query

Query.query_type = {
    FunctionArgument = "definition.function_argument",
    LocalVarName = "definition.local_name",
    Reference = "reference",
}

function Query.get_root(bufnr, filetype)
    local parser = parsers.get_parser(bufnr or 0, filetype)
    return parser:parse()[1]:root()
end

function Query.from_query_name(bufnr, filetype, query_name)
    local query = vim.treesitter.get_query(filetype, query_name)
    return Query:new(bufnr, filetype, query)
end

function Query:new(bufnr, filetype, query)
    return setmetatable({
        query = query,
        bufnr = bufnr,
        filetype = filetype,
        root = Query.get_root(bufnr, filetype),
    }, self)
end

function Query:pluck_by_capture(scope, captures)
    if type(captures) ~= "table" then
        captures = { captures }
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

    if not sexpr:find("@") then
        sexpr = sexpr .. " @tmp_capture"
    end
    local sexpr_query = vim.treesitter.parse_query(filetype, sexpr)

    local occurrences = {}
    for _, n in sexpr_query:iter_captures(scope, bufnr, 0, -1) do
        table.insert(occurrences, n)
    end

    return occurrences
end

return Query
