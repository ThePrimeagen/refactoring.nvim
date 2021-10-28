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
        -- this counts occurances of newline not lines in there with spaces
        local length = select(2, text:gsub("\n", "\n"))
        local diff = region.end_row - region.start_row

        if length ~= 0 and diff > length then
            length = length - 1
        end
        length = length - diff

        if start < cursor.row then
            add_rows = add_rows + length
        end
    end

    local r, _ = cursor:to_vim_win()
    local result_row = r + add_rows
    vim.schedule(function()
        vim.api.nvim_win_set_cursor(win, { result_row, 0 })
    end)
    reset()

    return true, refactor
end

return {
    adjust_cursor = adjust_cursor,
    reset = reset,
    add_change = add_change,
}
