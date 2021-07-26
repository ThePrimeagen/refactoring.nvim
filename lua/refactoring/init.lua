local extract = require("refactoring.extract")
local Config = require("refactoring.config")

local M = {
    extract = extract.extract,
    setup = function(config)
        Config.setup(config)
    end
}

return M


