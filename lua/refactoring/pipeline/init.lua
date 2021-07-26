local async = require('plenary.async')

---@class Pipeline
---Allows for pipelining tasks.  Tasks are functions that are expected to
---return ok (boolean), value (thing to be returned or passed to next task)
---
---Async tasks are functions that will take the previous result and a function
---to call back when done with ok, and value
---@field _tasks table: list of tasks
local Pipeline = {}
Pipeline.__index = Pipeline

function Pipeline:from_task(task)
    return setmetatable({
        _tasks = {task}
    }, self)
end

function Pipeline:add_task(task)
    table.insert(self._tasks, task)
    return self
end

function Pipeline:run(cb, err)
    err = err or error
    async.void(function()
        local ok = true
        local results = nil

        local idx = 1
        repeat
            ok, results = self._tasks[idx](results)
            idx = idx + 1
        until not ok or idx > #self._tasks

        if not ok then
            err(results)
        end

        cb(ok, results)
    end)()
end

return Pipeline
