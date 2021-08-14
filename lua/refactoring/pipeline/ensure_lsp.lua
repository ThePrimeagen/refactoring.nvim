local function ensure_lsp(refactor)
    local tbl = vim.lsp.buf_get_clients()

    local has_lsp = false
    for _, _ in pairs(tbl) do
        has_lsp = true
        break
    end

    return has_lsp,
        has_lsp and refactor
            or "Operation unavailable.  No LSP Server for buffer."
end

return ensure_lsp
