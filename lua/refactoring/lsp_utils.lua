local Region = require("refactoring.region")
local utils = require("refactoring.utils")

local M = {}

function M.delete_text(region)
    return region:to_lsp_text_edit("")
end

function M.insert_text(region, text)
    local clone = region:clone()

    -- TODO: I think this is a bug in neovim.
    -- The reason being to successfully insert at this character, we have to
    -- make the start != end col or else it consumes one character
    --
    -- LSP definition:
    -- https://microsoft.github.io/language-server-protocol/specification#textEdit
    clone.end_row = clone.start_row
    clone.end_col = clone.start_col - 1

    return clone:to_lsp_text_edit(text)
end

function M.replace_text(region, text)
    local delete_text = M.delete_text(region)
    local insert_text = M.insert_text(region, text)

    return insert_text, delete_text
end

return M
