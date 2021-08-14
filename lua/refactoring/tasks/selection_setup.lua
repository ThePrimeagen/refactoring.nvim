local Region = require("refactoring.region")

local function selection_setup(refactor)
    local region = Region:from_current_selection(refactor.bufnr)
    local scope = refactor.query:get_scope_over_region(region)

    refactor.region = region
    refactor.scope = scope

    if refactor.scope == nil then
        return false, "Scope is nil"
    end

    return true, refactor
end

return selection_setup
