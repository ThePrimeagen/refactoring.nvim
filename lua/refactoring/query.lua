local ts = vim.treesitter

--- local myEnum = Enum {
---     'Foo',          -- Takes value 1
---     'Bar',          -- Takes value 2
---     {'Qux', 10},    -- Takes value 10
---     'Baz',          -- Takes value 11
--- }

---@class refactor.Query
---@field query? vim.treesitter.Query
---@field bufnr integer
---@field filetype string
---@field root TSNode
local Query = {}
Query.__index = Query

Query.query_type = {
    FunctionArgument = "local.definition.function_argument",
    LocalVarName = "local.definition.local_name",
    Reference = "local.reference",
}

---@param bufnr integer
---@param filetype string
---@return TSNode
function Query.get_root(bufnr, filetype)
    local lang = ts.language.get_lang(filetype)
    local parser = ts.get_parser(bufnr, lang)
    if not parser then
        error(
            "No treesitter parser found. Install one using :TSInstall <language>"
        )
    end
    return parser:parse()[1]:root()
end

---@param bufnr integer
---@param filetype string
---@param query_name string
---@return refactor.Query
function Query.from_query_name(bufnr, filetype, query_name)
    local lang = ts.language.get_lang(filetype)

    if lang == nil then
        error(("No treesitter lang for filetype %s"):format(filetype))
    end

    local query = ts.query.get(lang, query_name)

    if query == nil then
        error(
            ("No query for treesiter lang %s and query_name %s"):format(
                lang,
                query_name
            )
        )
    end

    return Query:new(bufnr, filetype, query)
end

---@param bufnr integer
---@param filetype string
---@param query vim.treesitter.Query
---@return refactor.Query
function Query:new(bufnr, filetype, query)
    return setmetatable({
        query = query,
        bufnr = bufnr,
        filetype = filetype,
        root = Query.get_root(bufnr, filetype),
    }, self)
end

---@param scope TSNode
---@param captures string|string[]
---@return TSNode[]
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

---@param scope TSNode
---@param sexpr string
---@param bufnr integer
---@return TSNode[]
function Query.find_occurrences(scope, sexpr, bufnr)
    local filetype = vim.bo[bufnr].filetype

    if not sexpr:find("@") then
        --- @type string
        sexpr = sexpr .. " @tmp_capture"
    end

    local lang = ts.language.get_lang(filetype)
    local ok, sexpr_query = pcall(ts.query.parse, lang, sexpr)
    if not ok then
        error(("Invalid query: '%s'\n error: %s"):format(sexpr, sexpr_query))
    end

    local occurrences = {}
    for _, n in sexpr_query:iter_captures(scope, bufnr, 0, -1) do
        table.insert(occurrences, n)
    end

    return occurrences
end

return Query
