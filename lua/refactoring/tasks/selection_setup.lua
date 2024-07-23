local Region = require("refactoring.region")

---@param refactor Refactor
local function selection_setup(refactor)
    local utils = require("refactoring.utils")
    if utils.is_visual_mode() then
        utils.exit_to_normal_mode()
    end

    local region = Region:from_current_selection({
        bufnr = refactor.bufnr,
        include_end_of_line = refactor.ts.include_end_of_line,
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

return selection_setup
