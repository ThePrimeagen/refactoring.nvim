local Query, Query2 = require("refactoring.query")
local utils = require("refactoring.utils")

local function get_selected_locals(refactor)
    local local_defs = Query2:from_query(refactor.query)
        :with_scope(refactor.scope)
        :with_complement(refactor.region)
        :with_types({
            Query.query_type.FunctionArgument,
            Query.query_type.LocalVarName
        })
        :get_nodes()

    local region_refs = Query2:from_query(refactor.locals)
        :with_scope(refactor.scope)
        :with_intersect(refactor.region)
        :with_types({
            Query.query_type.Reference,
        })
        :get_nodes()

    local local_def_map = utils.node_text_to_set(local_defs)
    local region_refs_map = utils.node_text_to_set(region_refs)

    return utils.table_key_intersect(
        local_def_map,
        region_refs_map
    )
end

return get_selected_locals
