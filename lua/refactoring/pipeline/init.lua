local async = require("plenary.async")

---@class Pipeline
---Allows for pipelining tasks.  Tasks are functions that are expected to
---return ok (boolean), value (thing to be returned or passed to next task)
---
---Async tasks are functions that will take the previous result and a function
---to call back when done with ok, and value
---@field _tasks table: list of tasks
---@field _after Pipeline: A single pipeline to run next afterwords
local Pipeline = {}
Pipeline.__index = Pipeline

function Pipeline:from_task(task)
    return setmetatable({
        _tasks = { task },
    }, self)
end

function Pipeline:add_task(task)
    table.insert(self._tasks, task)
    return self
end

-- The primary purpose of this is to make post actions easy.
--
-- Imagine every refactor will have the following lines.
--
-- ```lua
-- :add_task(apply_text_edits)
-- :add_task(save)
-- :add_task(format)
-- :add_task(save)
-- ```
--
-- It would only make sense to allow for this pipeline to be attached
--
-- @param pipeline Pipeline the next pipeline to run after the primary pipeline has been an
function Pipeline:after(pipeline)
    self._after = pipeline
    return self
end

function Pipeline:run(cb, err, seed_value)
    err = err or error
    async.void(function()
        local ok = true
        local results = seed_value

        local idx = 1
        repeat
            ok, results = self._tasks[idx](results)
            idx = idx + 1
        until not ok or idx > #self._tasks

        -- Err should ultimately stop execution
        -- BUG: when visual mode has been triggered once and a refactor is executed we get:
        -- 5108: Error executing lua ...ck/packer/start/plenary.nvim/lua/plenary/async/async.lua:14: The coroutine
        -- failed with this message: ...start/refactoring.nvim/lua/refactoring/pipeline/init.lua:64: Scope is nil
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
