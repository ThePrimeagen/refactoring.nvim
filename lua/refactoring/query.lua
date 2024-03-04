--- local myEnum = Enum {
---     'Foo',          -- Takes value 1
---     'Bar',          -- Takes value 2
---     {'Qux', 10},    -- Takes value 10
---     'Baz',          -- Takes value 11
--- }

---@class RefactorQuery
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
    local lang = vim.treesitter.language.get_lang(filetype)
    local parser = vim.treesitter.get_parser(bufnr, lang)
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
---@return RefactorQuery
function Query.from_query_name(bufnr, filetype, query_name)
    local lang = vim.treesitter.language.get_lang(filetype)

    if lang == nil then
        error(string.format("No treesitter lang for filetype %s", filetype))
    end

    local query = vim.treesitter.query.get(lang, query_name)

    if query == nil then
        error(
            string.format(
                "No query for treesiter lang %s and query_name %s",
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
---@return RefactorQuery
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

    local lang = vim.treesitter.language.get_lang(filetype)
    local ok, sexpr_query = pcall(vim.treesitter.query.parse, lang, sexpr)
    if not ok then
        error(
            string.format("Invalid query: '%s'\n error: %s", sexpr, sexpr_query)
        )
    end

    local occurrences = {}
    for _, n in sexpr_query:iter_captures(scope, bufnr, 0, -1) do
        table.insert(occurrences, n)
    end

    return occurrences
end

return Query
