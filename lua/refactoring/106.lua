local dev = require("refactoring.dev")
dev.reload()

local Region = require("refactoring.region")
local ts_utils = require("nvim-treesitter.ts_utils")
local utils = require("refactoring.utils")
local Pipeline = require("refactoring.pipeline")
local selection_setup = require("refactoring.pipeline.selection_setup")
local refactor_setup = require("refactoring.pipeline.refactor_setup")
local get_input = require("refactoring.pipeline.get_input")
local format = require("refactoring.pipeline.format")
local save = require("refactoring.pipeline.save")
local get_selected_local_defs = require(
    "refactoring.pipeline.get_selected_local_defs"
)
local Config = require("refactoring.config")

local M = {}
-- 106
local function get_text_edits(
    selected_local_references,
    region,
    lang,
    scope_region,
    function_name,
    ret
)
    -- local declaration within the selection range.
    local lsp_text_edits = {}
    local extract_function =
        Config.get_config().code_generation[lang].extract_function({
            args = vim.tbl_keys(selected_local_references),
            body = region:get_text(),
            name = function_name,
            ret = ret,
        })
    table.insert(lsp_text_edits, {
        range = scope_region:to_lsp_range(),
        newText = string.format("\n%s", extract_function.create),
    })
    table.insert(lsp_text_edits, {
        range = region:to_lsp_range(),
        newText = string.format("\n%s", extract_function.call),
    })
    return lsp_text_edits
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

local function get_top_of_scope_region(scope)
    local scope_region = Region:from_node(scope)
    local lsp_range = scope_region:to_lsp_range()
    lsp_range.start.line = math.max(lsp_range.start.line - 1, 0)
    lsp_range["end"] = lsp_range.start

    return Region:from_lsp_range(lsp_range)
end

local function get_selected_local_references(refactor)
    local function_args = utils.get_function_args(refactor.scope, refactor.lang)
    local local_def_map = get_local_definitions(
        refactor.selected_local_defs,
        function_args
    )
    local local_references = utils.get_all_identifiers(
        refactor.scope,
        refactor.lang
    )
    local selected_local_references = {}

    for _, local_ref in pairs(local_references) do
        local local_name = ts_utils.get_node_text(local_ref)[1]
        if
            utils.range_contains_node(local_ref, refactor.region:to_ts())
            and local_def_map[local_name]
        then
            selected_local_references[local_name] = true
        end
    end

    return selected_local_references
end

M.extract_to_file = function(bufnr) end

M.extract = function(bufnr)
    Pipeline
        :from_task(refactor_setup(bufnr, Config.get_config()))
        :add_task(selection_setup)
        :add_task(get_selected_local_defs)
        :add_task(get_input("106: Extract Function Name > "))
        :add_task(function(refactor)
            local selected_local_references = get_selected_local_references(
                refactor
            )
            local scope_region = get_top_of_scope_region(refactor.scope)
            local function_name = refactor.input[1]

            --[[
            local first_local_def_name = ts_utils.get_node_text(
            utils.get_locals_defs(refactor.scope, refactor.lang)[1],
            0
            )[1]
            --]]

            -- TODO: Polor, could you also make the variable that is returned the first
            local text_edits = get_text_edits(
                selected_local_references,
                refactor.region,
                refactor.lang,
                scope_region,
                function_name,
                "fill_me_in_daddy"
            )

            vim.lsp.util.apply_text_edits(text_edits, 0)

            return true, refactor
        end)
        :add_task(save)
        :add_task(format)
        :add_task(save)
        :run(function(ok, result)
            print("Success!!", ok, result)
        end)
end

return M
