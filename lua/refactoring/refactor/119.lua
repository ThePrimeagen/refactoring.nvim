local Pipeline = require("refactoring.pipeline")
local selection_setup = require("refactoring.tasks.selection_setup")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local post_refactor = require("refactoring.tasks.post_refactor")
local extract_variable = require("refactoring.tasks.extract_variable")
local Config = require("refactoring.config")

local M = {}

function M.extract_var(bufnr)
    Pipeline
        :from_task(refactor_setup(bufnr, Config.get_config()))
        :add_task(selection_setup)
        :add_task(extract_variable)
        :after(post_refactor)
        :run()
end

return M
