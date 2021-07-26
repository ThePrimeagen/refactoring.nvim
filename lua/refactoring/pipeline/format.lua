local function format(refactor)
    local format_cmd = refactor.options.formatting[refactor.lang].cmd
    if not format_cmd then
        print("No Format Command", vim.inspect(refactor.options))
    else
        vim.cmd(format_cmd)
    end

    return true, refactor
end
return format
