local Region = require("refactoring.region")

---@param refactor Refactor
local function selection_setup(refactor)
    local mode = vim.api.nvim_get_mode().mode
    if mode == "v" or mode == "V" or mode == "vs" or mode == "Vs" then
        vim.cmd("norm! ")
    end

    local region = Region:from_current_selection({
        bufnr = refactor.bufnr,
        include_end_of_line = refactor.ts.include_end_of_line,
    })
    local region_node = region:to_ts_node(refactor.ts:get_root())
    local scope = refactor.ts:get_scope(region_node)

    refactor.region = region
    refactor.region_node = region_node
    refactor.scope = scope

    if refactor.scope == nil then
        return false, "Scope is nil"
    end

    return true, refactor
end

return selection_setup
