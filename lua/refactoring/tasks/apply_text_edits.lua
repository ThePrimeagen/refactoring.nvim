local add_change = require("refactoring.tasks.adjust_cursor").add_change
local Region = require("refactoring.region")

---@param refactor Refactor
---@return true, Refactor
local function refactor_apply_text_edits(refactor)
    if not refactor.text_edits then
        return true, refactor
    end

    local edits = {}

    for _, edit in pairs(refactor.text_edits) do
        local bufnr = edit.bufnr or refactor.buffers[1]
        if not edits[bufnr] then
            edits[bufnr] = {}
        end

        table.insert(edits[bufnr], edit)
        local region
        if
            edit.range["end"].line == edit.range["start"].line
            and edit.range["end"].character == edit.range["start"].character
        then
            region = Region:from_lsp_range_replace(edit.range, bufnr)
        else
            region = Region:from_lsp_range_insert(edit.range, bufnr)
        end
        add_change(region, edit.newText)
    end

    for bufnr, edit_set in pairs(edits) do
        vim.lsp.util.apply_text_edits(edit_set, bufnr, "utf-16")
    end

    return true, refactor
end

return refactor_apply_text_edits
