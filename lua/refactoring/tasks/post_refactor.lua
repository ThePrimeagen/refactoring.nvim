local Pipeline = require("refactoring.pipeline")
local format = require("refactoring.tasks.format")
local move_cursor = require("refactoring.tasks.move_cursor")
local apply_text_edits = require("refactoring.tasks.apply_text_edits")

-- TODO: How to save/reformat??? no idea
local function create_post_refactor_tasks()
    return Pipeline
        :from_task(apply_text_edits)
        :add_task(format)
        :add_task(move_cursor)
end

return create_post_refactor_tasks
