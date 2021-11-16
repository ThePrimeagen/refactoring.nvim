local utils = require("refactoring.utils")
local Query = require("refactoring.query")

-- @class Query2
-- @field query Query
-- @field types Query
-- @field scope tsnode
-- @field region RefactorRegion
-- @field filter function
-- @field region_calc_type string
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
    local root = self.scope
        or Query.get_root(self.query.bufnr, self.query.filetype)
    local nodes = self.query:pluck_by_capture(root, self.types)

    if self.region then
        nodes = self.region_calc_type == "intersect"
                and utils.region_intersect(nodes, self.region)
            or utils.region_complement(nodes, self.region)
    end

    if self.filter then
        nodes = vim.tbl_filter(self.filter, nodes)
    end

    return nodes
end

function Query2.get_references(scope, locals_query)
    return Query2
        :from_query(locals_query)
        :with_scope(scope)
        :with_types({
            Query.query_type.Reference,
        })
        :get_nodes()
end

return Query2
