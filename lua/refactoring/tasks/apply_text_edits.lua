local add_change = require("refactoring.tasks.adjust_cursor").add_change
local Region = require("refactoring.region")

---@param bufnr integer
---@param ns integer
---@param edit_set RefactorTextEdit[]
local function preview_highlight(bufnr, ns, edit_set)
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    for _, edit in pairs(edit_set) do
        if edit.newText == "" then
            vim.api.nvim_buf_set_extmark(
                bufnr,
                ns,
                edit.range.start.line,
                edit.range.start.character,
                {
                    end_row = edit.range.start.line + 1,
                    end_col = 0,
                    hl_eol = true,
                    strict = false,
                    hl_group = "Substitute",
                    right_gravity = false,
                    end_right_gravity = true,
                }
            )
        else
            vim.api.nvim_buf_set_extmark(
                bufnr,
                ns,
                edit.range.start.line,
                edit.range.start.character,
                {
                    end_col = edit.range["end"].character,
                    strict = false,
                    hl_group = "Substitute",
                    right_gravity = false,
                    end_right_gravity = true,
                }
            )
        end
    end
end

---@param refactor Refactor
---@return true, Refactor
local function refactor_apply_text_edits(refactor)
    if not refactor.text_edits then
        return true, refactor
    end

    --- @type table<integer, RefactorTextEdit[]>
    local edits = {}

    for _, edit in pairs(refactor.text_edits) do
        local bufnr = edit.bufnr or refactor.buffers[1]
        if not edits[bufnr] then
            edits[bufnr] = {}
        end

        table.insert(edits[bufnr], edit)
        --- @type RefactorRegion
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

    local ns = refactor.config:get()._preview_namespace

    for bufnr, edit_set in pairs(edits) do
        if ns then
            preview_highlight(bufnr, ns, edit_set)
        end
        vim.lsp.util.apply_text_edits(edit_set, bufnr, "utf-16")
    end

    return true, refactor
end

return refactor_apply_text_edits
