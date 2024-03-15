local Pipeline = require("refactoring.pipeline")
local Point = require("refactoring.point")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local debug_utils = require("refactoring.debug.debug_utils")

---@param bufnr integer
---@param config Config
---@return string out
local function get_path(bufnr, config)
    local out = nil ---@type string
    Pipeline:from_task(refactor_setup(bufnr, config))
        :add_task(
            ---@param refactor Refactor
            function(refactor)
                local point = Point:from_cursor()
                local ok, debug_path =
                    pcall(debug_utils.get_debug_path, refactor, point)
                if not ok then
                    return ok, debug_path
                end
                refactor.return_value = debug_path

                return true, refactor
            end
        )
        :run(
            ---@param ok boolean
            ---@param res Refactor
            function(ok, res)
                if ok then
                    out = res.return_value
                end
            end
        )

    return out
end

return get_path
