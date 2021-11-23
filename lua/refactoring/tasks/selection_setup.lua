local Region = require("refactoring.region")

local function selection_setup(refactor)
    local region = Region:from_current_selection(refactor.bufnr)
    local scope = refactor.query:get_scope_over_region(region)

    refactor.region = region
    refactor.scope = scope

    refactor.whitespace.highlight_start = vim.fn.indent(region.start_row)
    refactor.whitespace.highlight_end = vim.fn.indent(region.end_row)

    if refactor.scope == nil then
        return false, "Scope is nil"
    end

    return true, refactor
end

return selection_setup
