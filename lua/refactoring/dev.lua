local M = {}
M.reload = function()
    require("plenary.reload").reload_module("refactoring")
end

return M
