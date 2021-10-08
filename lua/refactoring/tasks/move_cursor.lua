local M = {}

local function get_line_count(text)
    return select(2, text:gsub("\n", "\n"))
end

-- TODO: Update this to not assume position of refactors
M.extract_move_cursor = function(refactor)
    -- Get first edit_set, don't care about bufnr
    local edit_set = nil
    for _, set in pairs(refactor.edits) do
        edit_set = set
        break
    end

    -- Assuming first edit is the new function
    local newFuncText = edit_set[1]["newText"]
    -- Counting lines in text
    local newFuncLineCount = get_line_count(newFuncText)
    -- Assuming second edit is replacement line
    local oldStartLine = edit_set[2]["range"]["start"]["line"]
    -- Difference in line for lsp vs cursor
    oldStartLine = oldStartLine + 1
    -- +1 for new line added before adding function
    local result_cursor_row = oldStartLine + newFuncLineCount + 1

    vim.api.nvim_win_set_cursor(0, { result_cursor_row, 0 })
end

local move_map = {
    extract = "extract_move_cursor",
}

local function move_cursor(refactor)
    if move_map[refactor.name] ~= nil then
        M[move_map[refactor.name]](refactor)
    end

    return true, refactor
end
return move_cursor
