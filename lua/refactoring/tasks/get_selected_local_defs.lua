local utils = require("refactoring.utils")
local Query = require("refactoring.query")

local function get_selected_local_defs(refactor)
    local local_defs = vim.tbl_filter(
        function(node)
            return not utils.range_contains_node(node, refactor.region:to_ts())
        end,
        refactor.query:pluck_by_capture(
            refactor.scope,
            Query.query_type.LocalVarName
        )
    )

    refactor.selected_local_defs = local_defs
    return true, refactor
end

return get_selected_local_defs
