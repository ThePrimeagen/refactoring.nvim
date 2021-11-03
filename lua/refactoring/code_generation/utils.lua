local Query = require("refactoring.query")
local Region = require("refactoring.region")

local M = {}

function M.stringify_code(code)
    return type(code) == "table" and table.concat(code, "\n") or code
end

function M.get_class_name(query, scope)
    local class_name_node = query:pluck_by_capture(
        scope,
        Query.query_type.ClassName
    )[1]
    local region = Region:from_node(class_name_node)
    return region:get_text()[1]
end

function M.get_class_type(query, scope)
    local class_type_node = query:pluck_by_capture(
        scope,
        Query.query_type.ClassType
    )[1]
    local region = Region:from_node(class_type_node)
    return region:get_text()[1]
end

return M
