--- @param refactor Refactor
---@param code_gen_operations code_gen[]|class_code_gen[]|indent_code_gen[]
---@return boolean, Refactor
local function ensure_code_gen(refactor, code_gen_operations)
    for _, code_gen_operation in ipairs(code_gen_operations) do
        if refactor.code[code_gen_operation] == nil then
            error(
                string.format(
                    "No %s function for code generator for %s",
                    code_gen_operation,
                    refactor.filetype
                )
            )
        end
    end
    return true, refactor
end

return ensure_code_gen
