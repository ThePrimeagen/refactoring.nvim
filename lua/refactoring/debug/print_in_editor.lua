local Pipeline = require("refactoring.pipeline")
local Point = require("refactoring.point")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local post_refactor = require("refactoring.tasks.post_refactor")
local debug_utils = require("refactoring.debug.debug_utils")

local function print_in_editor(bufnr, config)
    return Pipeline
        :from_task(refactor_setup(bufnr, config))
        :add_task(function(refactor)
            local point = Point:from_cursor()
            local debug_path = debug_utils.get_debug_path(refactor, point)

            print(vim.inspect(debug_path))

            return true, refactor
        end)
        :after(post_refactor)
        :run()
end

return print_in_editor
