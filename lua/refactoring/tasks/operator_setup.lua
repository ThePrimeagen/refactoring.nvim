---@param refactor Refactor
local function operator_setup(refactor)
    local Region = require("refactoring.region")

    local region = Region:from_motion({
        bufnr = refactor.bufnr,
        include_end_of_line = refactor.ts.include_end_of_line,
        type = refactor.region_type,
    })
    local region_node = region:to_ts_node(refactor.ts:get_root())
    local ok, scope = pcall(refactor.ts.get_scope, refactor.ts, region_node)
    if not ok then
        return ok, scope
    end

    refactor.region = region
    refactor.region_node = region_node
    refactor.scope = scope

    if refactor.scope == nil then
        return false, "Scope is nil"
    end

    return true, refactor
end

return operator_setup
