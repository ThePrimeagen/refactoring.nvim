local M = {}

function M.notify(text)
    vim.notify(text, vim.log.levels.INFO)
end

function M.error(text)
    vim.notify(text, vim.log.levels.ERROR)
end

return M
