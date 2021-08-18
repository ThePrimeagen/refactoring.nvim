local utils = require("refactoring.utils")

local M = {}

-- LSP will provide a file name with the uri
-- Will it be any other uri? But I doubt we can refactor anything else, so the
-- other checks should fail.
local function strip_file_uri(file)
    if file:sub(1, #"file://") == "file://" then
        return file:sub(#"file://" + 1)
    end
    return file
end

function M.lsp_uri_to_bufnr(file)
    return vim.fn.bufnr(strip_file_uri(file))
end

function M.get_definition_under_cursor(bufnr)
    local def = vim.lsp.buf_request_sync(
        bufnr,
        "textDocument/definition",
        vim.lsp.util.make_position_params()
    )

    local target = utils.take_one(def, function(_, v)
        return v.result and #v.result > 0
    end)

    if not target then
        error(
            "LSP Failed to find definition. You either don't have an LSP or it was unable to local definition of identifier under cursor."
        )
        -- I think I need TJ to tell me what function does bufnr replacement
    end

    return target[1]
end

function M.lsp_range_contains(range, point)
    local start_point = range.start
    local end_point = range["end"]

    if point.line < start_point.line then
        return false
    elseif
        point.line == start_point.line
        and point.character < start_point.character
    then
        return false
    elseif point.line > end_point.line then
        return false
    elseif
        point.line == end_point.line
        and point.character > end_point.character
    then
        return false
    end
    return true
end

-- TODO: THis isn't very pretty.  What can we do to remove this.  I feel like
-- that silly look that looks for the first item, we should probably pull that out
function M.get_references_under_cursor(bufnr)
    local params = vim.lsp.util.make_position_params()
    params.context = {
        includeDeclaration = false,
    }

    local references = vim.lsp.buf_request_sync(
        bufnr,
        "textDocument/references",
        params
    )

    local reference = utils.take_one(references)
    if not references then
        return {}
    end

    -- I always get troubles with vim.tbl_filter
    -- Also, context apparently doesn't strip out declaration hence this extra
    -- layer of filtering... :(
    --
    -- I'll leave it here until I can fix it
    local out = {}
    for _, ref in pairs(reference.result) do
        if not M.lsp_range_contains(ref.range, params.position) then
            table.insert(out, ref)
        end
    end

    return out
end

return M
