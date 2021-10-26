local M = {}

function M.bor(a, b)
    if M.band(a, b) then
        return a
    end
    return a + b
end

-- single flags
function M.band(a, b)
    local a_fixed = a % (b * 2)
    return a_fixed / b >= 1
end

return M
