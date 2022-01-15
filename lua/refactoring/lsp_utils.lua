local code = require("refactoring.code_generation")
local Region = require("refactoring.region")

local M = {}

-- TODO: I think this is a bug in neovim.
-- The reason being to successfully insert at this character, we have to
-- make the start != end col or else it consumes one character
--
-- LSP definition:
-- https://microsoft.github.io/language-server-protocol/specification#textEdit
local function fix_insertion_region(region)
    region.end_row = region.start_row
    region.end_col = region.start_col - 1
    return region
end

local function to_region(pointOrRegion)
    if not pointOrRegion.end_row then
        return Region:from_point(pointOrRegion)
    end
    return pointOrRegion
end

function M.delete_text(region)
    return region:to_lsp_text_edit("")
end

function M.insert_new_line_text(pointOrRegion, text, opts)
    opts = opts or {
        below = true,
    }

    local region = to_region(pointOrRegion)

    -- what is after?  I just assume 10000 is equivalent
    if opts.below then
        region.start_col = 10000
        region.end_col = 10000
        text = code.new_line() .. text
    else
        region.start_col = 1
        region.end_col = 0
        text = text .. code.new_line()
    end
    return region:to_lsp_text_edit(text)
end

function M.insert_text(pointOrRegion, text)
    local region = to_region(pointOrRegion)
    local clone = region:clone()
    fix_insertion_region(clone)

    return clone:to_lsp_text_edit(text)
end

function M.replace_text(region, text)
    local delete_text = M.delete_text(region)
    local insert_text = M.insert_text(region, text)

    return insert_text, delete_text
end

return M
