local Region = require("refactoring.region")

-- TODO: You can have more than one definition.
-- Which one do I take?  What are the risks of the first one
local function lsp_definition_setup(refactor)
    local def = vim.lsp.buf_request_sync(
        refactor.bufnr,
        "textDocument/definition",
        vim.lsp.util.make_position_params()
    )

    local target = nil
    for _, v in pairs(def) do
        if v.result and #v.result > 0 then
            target = v.result
            break
        end
    end

    if not target then
        return false,
            "LSP Failed to find definition. You either don't have an LSP or it was unable to local definition of identifier under cursor."
        -- I think I need TJ to tell me what function does bufnr replacement
    end

    refactor.lsp_definition = target[1]
    refactor.lsp_definition_region = Region:from_lsp_range(
        target[1].targetRange
    )

    return true, refactor
end

return lsp_definition_setup
