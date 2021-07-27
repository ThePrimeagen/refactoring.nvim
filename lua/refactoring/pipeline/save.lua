-- TODO: Likely unnecessary, but it could be nice if we needed to add any logic
-- to the saving process
local function save(refactor)
    for _, bufnr in pairs(refactor.buffers) do
        -- TODO: Window?
        vim.api.nvim_win_set_buf(0, bufnr)
        vim.cmd([[ :w ]])
    end
    return true, refactor
end
return save
