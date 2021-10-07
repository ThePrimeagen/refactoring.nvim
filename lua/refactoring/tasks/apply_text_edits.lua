local function get_text(edit)
    if edit.add_newline or edit.add_newline == nil then
        return string.format("\n%s", edit.text)
    end
    return edit.text
end

local function apply_text_edits(refactor)
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
        else
            table.insert(
                edits[bufnr],
                edit.region:to_lsp_text_edit(get_text(edit))
            )
        end
    end

    for bufnr, edit_set in pairs(edits) do
        local status, retval = pcall(
            vim.lsp.util.apply_text_edits,
            edit_set,
            bufnr
        )
        if status == false then
            -- HACK:: Figure out why this started failing for cursor position
            -- print ("Return Value: ", retval)
            -- If not the expected error, throw it
            if not string.match(retval, "Cursor position outside buffer") then
                error(retval)
            end
        end
    end
    return true, refactor
end

return apply_text_edits
