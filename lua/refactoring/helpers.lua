local Pipeline = require("refactoring.pipeline")
local format = require("refactoring.pipeline.format")
-- local save = require("refactoring.pipeline.save")
local apply_text_edits = require("refactoring.pipeline.apply_text_edits")

local M = {}

-- TODO: How to save/reformat??? no idea
-- NOTE: @danielnehrig suggestion
-- add to the setup object bool flag
-- which enables and disables formatting
-- UX wise i think it makes sens POST refactor
-- to trigger a async LSP formatting action
-- but not saveing
-- most people have their LSP do the formatting task
-- but there is also the option for something like neoformat
-- we also could expose the post refactor method as a callback in the setup func or vim event
-- that way the user has controll over the post refactor logic and would support third party
-- refactor plugins
function M.create_post_refactor_tasks()
    return Pipeline:from_task(apply_text_edits):add_task(format)

    -- :add_task(save)
    -- :add_task(save)
end

return M
