local Pipeline = require("refactoring.pipeline")
-- local format = require("refactoring.pipeline.format")
-- local save = require("refactoring.pipeline.save")
local apply_text_edits = require("refactoring.pipeline.apply_text_edits")

local M = {}

-- TODO: How to save/reformat??? no idea
function M.create_post_refactor_tasks()
    return Pipeline
        :from_task(apply_text_edits)
        -- :add_task(save)
        -- :add_task(format)
        -- :add_task(save)
end

return M
