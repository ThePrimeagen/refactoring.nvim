local bits = require("refactoring.bits")

local Version = {
    Scopes = 0x1,
    Locals = 0x2,
    Classes = 0x3,
}

function Version.ensure_version(version, ...)
    local versions = ...

    local has_flags = true
    for i = 1, select("#", versions) do
        has_flags = has_flags and bits.band(version, select(i, versions))
    end

    if not has_flags then
        error("This operation isn't supported for this language.")
    end
end

return Version
