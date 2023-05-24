local async = require("plenary.async")

---@class RefactorPipeline
---Allows for pipelining tasks.  Tasks are functions that are expected to
---return ok (boolean), value (thing to be returned or passed to next task)
---
---Async tasks are functions that will take the previous result and a function
---to call back when done with ok, and value
---@field _tasks table: list of tasks
---@field _after RefactorPipeline: A single pipeline to run next afterwords
local Pipeline = {}
Pipeline.__index = Pipeline

---@param task fun(): boolean, any
---@return RefactorPipeline
function Pipeline:from_task(task)
    return setmetatable({
        _tasks = { task },
    }, self)
end

---@param task function
---@return RefactorPipeline
function Pipeline:add_task(task)
    table.insert(self._tasks, task)
    return self
end

--- The primary purpose of this is to make post actions easy.
---
--- Imagine every refactor will have the following lines.
---
--- ```lua
--- :add_task(apply_text_edits)
--- :add_task(save)
--- :add_task(format)
--- :add_task(save)
--- ```
---
--- It would only make sense to allow for this pipeline to be attached
---
---@param pipeline RefactorPipeline|function: the next pipeline to run after the primary pipeline has been an
function Pipeline:after(pipeline)
    if type(pipeline) == "function" then
        pipeline = pipeline()
    end
    self._after = pipeline
    return self
end

---@param cb function|nil
---@param err function|nil
---@param seed_value any|nil
function Pipeline:run(cb, err, seed_value)
    err = err or error
    async.void(function()
        local ok
        local results = seed_value

        local idx = 1
        repeat
            ok, results = self._tasks[idx](results)
            idx = idx + 1
        until not ok or idx > #self._tasks

        -- Err should ultimately stop execution
        if not ok then
            err(results)
            return
        end

        if self._after then
            self._after:run(cb, err, results)
        elseif cb then
            cb(ok, results)
        end
    end)()
end

return Pipeline
