local Pipeline = require("refactoring.pipeline")
local Point = require("refactoring.point")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local debug_utils = require("refactoring.debug.debug_utils")

local function get_path(bufnr, config)
    local out = nil
    Pipeline:from_task(refactor_setup(bufnr, config))
        :add_task(
            ---@param refactor Refactor
            function(refactor)
                local point = Point:from_cursor()
                local debug_path = debug_utils.get_debug_path(refactor, point)
                refactor.return_value = debug_path

                return true, refactor
            end
        )
        :run(function(ok, res)
            if ok then
                out = res.return_value
            end
        end)

    return out
end

return get_path
