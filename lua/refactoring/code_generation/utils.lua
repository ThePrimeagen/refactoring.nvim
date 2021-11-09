local M = {}

function M.stringify_code(code)
    return type(code) == "table" and table.concat(code, "\n") or code
end

return M
