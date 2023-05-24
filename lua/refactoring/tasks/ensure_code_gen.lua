--- @param refactor Refactor
---@param code_gen_operations string[]
---@return boolean, Refactor|string
local function ensure_code_gen(refactor, code_gen_operations)
    for _, code_gen_operation in ipairs(code_gen_operations) do
        if refactor.code[code_gen_operation] == nil then
            return false,
                string.format(
                    "No %s function for code generator for %s",
                    code_gen_operation,
                    refactor.filetype
                )
        end
    end
    return true, refactor
end

return ensure_code_gen
