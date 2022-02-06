local utils = require("refactoring.utils")

local changes = {}
local function add_change(region, text)
    table.insert(changes, { region, text })
end

local function reset()
    changes = {}
end

local function get_rows(cursor)
    local add_rows = 0
    for _, edit in pairs(changes) do
        local region = edit[1]
        local text = edit[2]
        local start = region.start_row
        local text_length = #utils.split_string(text, "\n")
        local diff = region.end_row - region.start_row

        if region.start_row == region.end_row and text_length > 0 then
            diff = diff + 1
        end

        local length = text_length - diff
        if start < cursor.row then
            add_rows = add_rows + length
        end
    end
    return add_rows
end

-- cursor is the original cursor before the refactor
local function adjust_cursor(refactor)
    local win = refactor.win
    local cursor = refactor.cursor
    local add_rows = get_rows(cursor)
    local r, _ = cursor:to_vim_win()
    local result_row = r + add_rows
    -- HACK: storing these value to be used by indent
    refactor.result_cursor_row = result_row
    local _, col = cursor:to_vim()
    refactor.result_cursor_col = col
    vim.schedule(function()
        vim.api.nvim_win_set_cursor(win, {
            result_row,
            col,
        })
    end)
    reset()

    return true, refactor
end

return {
    adjust_cursor = adjust_cursor,
    reset = reset,
    add_change = add_change,
}
