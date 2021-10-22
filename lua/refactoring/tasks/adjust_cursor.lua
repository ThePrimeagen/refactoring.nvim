local utils = require("refactoring.utils")

local changes = {}
local function add_change(region, text)
    table.insert(changes, { region, text })
end

local function reset()
    changes = {}
end

-- cursor is the original cursor before the refactor
local function adjust_cursor(refactor)
    local win = refactor.win
    local cursor = refactor.cursor
    local add_rows = 0
    for _, edit in pairs(changes) do
        local region = edit[1]
        local text = edit[2]

        local start = region.start_row
        local length = #utils.split_string(text, "\n")
        local diff = region.end_row - region.start_row

        if
            region.start_row ~= region.end_row
            or region.end_col ~= region.start_col
        then
            diff = diff + 1
        end

        length = length - diff

        if start < cursor.row then
            add_rows = add_rows + length
        end
    end

    local r, c = cursor:to_vim_win()
    vim.schedule(function()
        vim.api.nvim_win_set_cursor(win, { r + add_rows, c })
    end)

    return true, refactor
end

return {
    adjust_cursor = adjust_cursor,
    reset = reset,
    add_change = add_change,
}
