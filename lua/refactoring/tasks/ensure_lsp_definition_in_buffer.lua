local utils = require("refactoring.utils")

local function ensure_lsp_definition_in_buffer(refactor)
    if not refactor.lsp_definition then
        return false,
            "lsp_definition_setup has to be ran before this task can run."
    end

    local target_bufnr = utils.lsp_uri_to_bufnr(
        refactor.lsp_definition.targetUri
    )
    if target_bufnr == -1 or target_bufnr ~= refactor.bufnr then
        return false,
            "Definition of identifier is found outside current file, cannot inline."
    end

    return true, refactor
end

return ensure_lsp_definition_in_buffer
