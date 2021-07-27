local utils = require("refactoring.utils")

local function get_selected_local_defs(refactor)
    local local_defs = vim.tbl_filter(function(node)
        return not utils.range_contains_node(node, refactor.region:to_ts())
    end, utils.get_local_defs(
        refactor.scope,
        refactor.lang
    ))

    refactor.selected_local_defs = local_defs
    return true, refactor
end

return get_selected_local_defs
