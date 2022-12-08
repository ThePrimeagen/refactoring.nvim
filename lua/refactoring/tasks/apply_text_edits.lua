local add_change = require("refactoring.tasks.adjust_cursor").add_change
local Region = require("refactoring.region")

local function get_text(edit)
    if edit.add_newline or edit.add_newline == nil then
        return string.format("\n%s", edit.text)
    end
    return edit.text
end

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

        -- TODO: We should think of a way to make this work with better for both
        -- new line auto additions and just lsp generated content
        if edit.newText then
            table.insert(edits[bufnr], edit)
            add_change(Region:from_lsp_range(edit.range, bufnr), edit.newText)
        else
            local newText = get_text(edit)
            table.insert(edits[bufnr], edit.region:to_lsp_text_edit(newText))
            add_change(edit.region, newText)
        end
    end


    for bufnr, edit_set in pairs(edits) do
        vim.lsp.util.apply_text_edits(edit_set, bufnr, "utf-16")
    end

    return true, refactor
end

return refactor_apply_text_edits
