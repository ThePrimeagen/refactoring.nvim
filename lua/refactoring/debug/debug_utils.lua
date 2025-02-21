local M = {}

local ts = vim.treesitter
local iter = vim.iter

---@param refactor Refactor
---@param point RefactorPoint
function M.get_debug_path(refactor, point)
    local node = assert(ts.get_node({
        bufnr = refactor.bufnr,
        pos = { point.row - 1, point.col },
    }))
    local debug_path = refactor.ts:get_debug_path(node)

    return iter(debug_path):map(tostring):rev():join("#")
end

return M
