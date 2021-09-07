local Query, Query2 = require("refactoring.query")

local function get_selected_local_defs(refactor)
    refactor.selected_local_defs = Query2:from_query(refactor.query)
        :with_types({Query.query_type.LocalVarName})
        :with_scope(refactor.scope)
        :with_intersect(refactor.region)
        :get_nodes()

    return true, refactor
end

return get_selected_local_defs
