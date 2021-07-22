local M = {}

-- TODO: Probably do it this way... seems mucho better
-- https://github.com/neovim/neovim/blob/6f48c018b526a776e38e94f58769c30141de9e0c/runtime/lua/vim/lsp/util.lua#L243
function M.move_text(buf, from_start_row, from_end_row, to_start_row)
    if from_start_row <= to_start_row and from_end_row >= to_start_row then
        error(
            "vim-helpers#move_text has been provided a destination within the removal location.  Impossible!"
        )
    end

    if not vim.api.nvim_buf_is_valid(buf) then
        error("vim-helpers#move_text provided buf does not exist.")
    end

    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    for idx = from_start_row, from_end_row do
        local to_remove_idx = from_start_row > to_start_row and idx
            or from_start_row
        local line = lines[to_remove_idx]

        table.remove(lines, to_remove_idx)
        table.insert(lines, to_start_row, line)
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

return M
