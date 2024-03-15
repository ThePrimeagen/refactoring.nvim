local M = {}

---@param refactor Refactor
---@param point RefactorPoint
function M.get_debug_path(refactor, point)
    local node = point:to_ts_node(refactor.ts:get_root())
    local debug_path = refactor.ts:get_debug_path(node)

    ---@type string[]
    local path = {}
    for i = #debug_path, 1, -1 do
        table.insert(path, tostring(debug_path[i]))
    end
    return table.concat(path, "#")
end

return M
