local bits = require("refactoring.bits")

---@class RefactorVersion
---@field version number: the flag set
local Version = {}
Version.__index = Version

function Version:new(...)
    local version = 0
    for i = 1, select("#", ...) do
        version = bits.bor(version, select(i, ...))
    end

    return setmetatable({
        version = version,
    }, self)
end

function Version:ensure_version(...)
    local has_flags = true
    for i = 1, select("#", ...) do
        has_flags = has_flags and bits.band(self.version, select(i, ...))
    end

    if not has_flags then
        error("This operation isn't supported for this language.")
    end
end

return Version
