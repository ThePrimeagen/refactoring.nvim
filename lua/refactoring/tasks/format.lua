local function format(refactor)
    local format_cmd =
        refactor.options.get_formatting_for(
            refactor.filetype
        ).cmd
    if format_cmd then
        for _, bufnr in pairs(refactor.buffers) do
            -- This makes it locally much more predictable
            vim.schedule(function()
                vim.api.nvim_win_set_buf(0, bufnr)
                vim.cmd(format_cmd)
            end)
        end
    end

    return true, refactor
end
return format
