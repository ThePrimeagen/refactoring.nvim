local function format(refactor)
    local format_cmd = refactor.options.formatting[refactor.lang].cmd
    if not format_cmd then
        print("No Format Command", vim.inspect(refactor.options))
    else
        for _, bufnr in pairs(refactor.buffers) do
            -- TODO: Window?
            vim.api.nvim_win_set_buf(0, bufnr)
            vim.cmd(format_cmd)
        end
    end

    return true, refactor
end
return format
