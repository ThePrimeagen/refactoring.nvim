local Region = require("refactoring.region")

local function selection_setup(refactor)
    local use_motion = refactor.config:get().use_motion
    local region = Region:from_current_selection(use_motion)
    local region_node = region:to_ts_node(refactor.ts:get_root())
    local scope = refactor.ts:get_scope(region_node)

    refactor.region = region
    refactor.region_node = region_node
    refactor.scope = scope
    refactor.whitespace.highlight_start = vim.fn.indent(region.start_row)
    refactor.whitespace.highlight_end = vim.fn.indent(region.end_row)

    if refactor.scope == nil then
        return false, "Scope is nil"
    end

    return true, refactor
end

return selection_setup
