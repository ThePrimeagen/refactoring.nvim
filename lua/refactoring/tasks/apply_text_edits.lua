local utils = require("refactoring.utils")

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
    -- Clean this up so that I don't have to have two tables
    local text_moved = {}

    for _, edit in pairs(refactor.text_edits) do
        local bufnr = edit.bufnr or refactor.buffers[1]
        if not edits[bufnr] then
            edits[bufnr] = {}
        end

        -- TODO: We should think of a way to make this work with better for both
        -- new line auto additions and just lsp generated content
        local start = 0
        local length = 0
        if edit.newText then
            table.insert(edits[bufnr], edit)
            start = edit.start.line
            length = #utils.split_string(edits.newText, "\n")
            if edit.newText == "" then
                length = length * -1
            end
        else
            local newText = get_text(edit)

            table.insert(edits[bufnr], edit.region:to_lsp_text_edit(newText))

            start = edit.region.start_row
            length = #utils.split_string(newText, "\n")
            local diff = edit.region.end_row - edit.region.start_row

            if
                edit.region.start_row ~= edit.region.end_row
                or edit.region.end_col ~= edit.region.start_col
            then
                diff = diff + 1
            end

            print(
                "HELLO WORLD",
                vim.inspect(edit.region),
                length,
                diff,
                length - diff
            )

            length = length - diff
        end

        if refactor.bufnr == bufnr then
            table.insert(text_moved, {
                start = start,
                length = length,
            })
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

    -- TODO: should I make this its own task?
    -- teddy weigh in by changing this if you feel different.
    local cursor = refactor.cursor_point
    local add_rows = 0
    for _, v in pairs(text_moved) do
        if v.start < cursor.row then
            print("adding", v.length)
            add_rows = add_rows + v.length
        end
    end
    print("total", add_rows)

    local r, c = cursor:to_vim_win()
    vim.schedule(function()
        vim.api.nvim_win_set_cursor(refactor.win, { r + add_rows, c })
    end)

    return true, refactor
end

return apply_text_edits
