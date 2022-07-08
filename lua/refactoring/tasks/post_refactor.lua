local Pipeline = require("refactoring.pipeline")
local format = require("refactoring.tasks.format")
local adjust_cursor = require("refactoring.tasks.adjust_cursor").adjust_cursor
local apply_text_edits = require("refactoring.tasks.apply_text_edits")

local M = {}

-- TODO: How to save/reformat??? no idea
M.post_refactor = function()
    return Pipeline:from_task(apply_text_edits)
        :add_task(format)
        :add_task(adjust_cursor)
end

-- needed when another file is generated
M.no_cursor_post_refactor = function()
    return Pipeline:from_task(apply_text_edits):add_task(format)
end

return M
