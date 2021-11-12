local config = require("refactoring.config")
local TreeSitter = require("refactoring.treesitter")
local Point = require("refactoring.point")
local apply_text_edits = require("refactoring.tasks.apply_text_edits")

local function printDebug(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    local ts = TreeSitter.get_treesitter(bufnr)
    local point = Point:from_cursor(bufnr)
    local node = point:to_ts_node(ts:get_root())
    local debug_path = ts:get_debug_path(node)

    local path = {}
    for i = #debug_path, 1, -1 do
        table.insert(path, ts:to_string(debug_path[i]))
    end

    local code_gen = config.get_code_generation_for()
    if not code_gen then
        error(string.format("No code generator for %s", vim.bo[0].ft))
    end

    local debug_path_concat = table.concat(path, "#")
    local print_statement = code_gen.print(debug_path_concat)

    local refactor = {
        text_edits = {
            {
                region = point:to_region(),
                text = print_statement,
            },
        },
        buffers = { bufnr },
    }
    apply_text_edits(refactor)
end

return printDebug
