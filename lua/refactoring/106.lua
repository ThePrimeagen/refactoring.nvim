local dev = require("refactoring.dev")
dev.reload()

local ts_utils = require("nvim-treesitter.ts_utils")
local utils = require("refactoring.utils")
local vim_helpers = require("refactoring.vim-helpers")

local REFACTORING = {}
local REFACTORING_OPTIONS = {
    code_generation = {
        lua = {
            extract_function = function(opts)
                return {
                    create = table.concat(vim.tbl_flatten({
                        string.format("local function %s(%s)", opts.name, table.concat(opts.args, ", ")),
                        opts.body,
                        "end",
                        ""
                    }), "\n"),

                    call = string.format("%s(%s)", opts.name, table.concat(opts.args, ", ")),
                }
            end,
        }
    }
}

local function get_selection_range()
    local _, start_row, start_col, _ = unpack(vim.fn.getpos("'<"))
    local _, end_row, _, _ = unpack(vim.fn.getpos("'>"))
    local end_col = vim.fn.col("'>")

    -- end_col :: TS is 0 based, and '> on line selections is char_count + 1
    -- I think - 2 is correct on
    --
    -- end_row : end_row is exclusive in TS, so we don't minus
    return start_row, start_col, end_row, end_col
end

local function vim_range_to_ts_range(start_row, start_col, end_row, end_col)
    return start_row - 1, start_col, end_row - 1, end_col
end

-- 106
local function get_text_edits(selected_local_references, end_row, lang, start_col, start_row, end_col, scope_range, function_name)
    -- local declaration within the selection range.
    local lsp_text_edits = {}
    local extract_function = REFACTORING_OPTIONS.code_generation[lang].extract_function({
        args = vim.tbl_keys(selected_local_references),
        body = vim.api.nvim_buf_get_lines(0, start_row, end_row, false),
        name = function_name,
    })
    table.insert(lsp_text_edits, {
        range = scope_range,
        newText = string.format("\n%s", extract_function.create)
    })
    table.insert(lsp_text_edits, {
        range = {
            start = {line = start_row, character = start_col},
            ["end"] = {line = end_row, character = end_col}
        },
        newText = string.format("\n%s", extract_function.call)
    })
    return lsp_text_edits
end

local function get_scope_range(scope)
    -- vim_helpers.move_text(0, start_row, end_row, scope:range())
    local scope_range = ts_utils.node_to_lsp_range(scope)
    scope_range.start.line = scope_range.start.line - 1
    scope_range["end"] = scope_range.start

    return scope_range
end

local function get_local_definitions(local_defs, function_args)
    local local_def_map = {}

    for _, def in pairs(local_defs) do
        local_def_map[ts_utils.get_node_text(def)[1]] = true
    end
    for _, def in pairs(function_args) do
        local_def_map[ts_utils.get_node_text(def)[1]] = true
    end

    return local_def_map
end

REFACTORING.extract = function(bufnr)
    -- lua 1  based index
    -- vim apis are 1 based
    -- treesitter is 0 based
    -- first entry (1), line 1, row 0
    bufnr = bufnr or 0

    local lang = vim.bo.filetype
    local start_row, start_col, end_row, end_col = get_selection_range()
    local ts_start_row, ts_start_col, ts_end_row, ts_end_col =
        vim_range_to_ts_range(start_row, start_col, end_row, end_col)
    local root = utils.get_root(lang)
    local scope = utils.get_scope_over_selection(root, start_row, start_col, end_row + 1, end_col, lang)

    if scope == nil then
        error("Scope is nil")
    end

    local local_defs = vim.tbl_filter(function(node)
        return not utils.range_contains_node(node, ts_start_row, ts_start_col, ts_end_row, ts_end_col)
    end, utils.get_locals_defs(scope, lang))

    local function_args = utils.get_function_args(scope, lang)
    local local_def_map = get_local_definitions(local_defs, function_args)
    local local_references = utils.get_all_identifiers(scope, lang)
    local selected_local_references = {}

    for _, local_ref in pairs(local_references) do
        local local_name = ts_utils.get_node_text(local_ref)[1]
        if utils.range_contains_node(local_ref, ts_start_row, ts_start_col, ts_end_row, ts_end_col) and
            local_def_map[local_name] then
            selected_local_references[local_name] = true
        end
    end

    -- TODO: Probably use text edit
    local scope_range = get_scope_range(scope)

    -- TODO: Polar, nvim_buf_get_lines doesn't actually get the highlighted
    -- region, instead the highlighted rows
    local function_name = vim.fn.input("106: Extract Function Name > ")

    -- TODO: Polor, could you also make the variable that is returned the first
    local text_edits = get_text_edits(selected_local_references, end_row, lang, start_col, start_row, end_col, scope_range, function_name)
    vim.lsp.util.apply_text_edits(text_edits, 0)
end

REFACTORING.extract()

return REFACTORING
