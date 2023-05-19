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
        local bufnr = refactor.buffers[1]
        if not edits[bufnr] then
            edits[bufnr] = {}
        end

        table.insert(edits[bufnr], edit)
        add_change(
            -- TODO (TheLeoP): Probably this is wrong and I should evaluate whether to insert or replace x2
            Region:from_lsp_range_insert(edit.range, bufnr),
            edit.newText
        )
    end

    for bufnr, edit_set in pairs(edits) do
        vim.lsp.util.apply_text_edits(edit_set, bufnr, "utf-16")
    end

    return true, refactor
end

return refactor_apply_text_edits
