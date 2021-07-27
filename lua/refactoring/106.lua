local dev = require("refactoring.dev")
dev.reload()

local ts_utils = require("nvim-treesitter.ts_utils")
local utils = require("refactoring.utils")
local Pipeline = require("refactoring.pipeline")
local selection_setup = require("refactoring.pipeline.selection_setup")
local refactor_setup = require("refactoring.pipeline.refactor_setup")
local get_input = require("refactoring.pipeline.get_input")
local create_file = require("refactoring.pipeline.create_file")
local helpers = require("refactoring.helpers")
local get_selected_local_defs = require(
    "refactoring.pipeline.get_selected_local_defs"
)
local Config = require("refactoring.config")

local M = {}

local function get_code(
    lang,
    region,
    selected_local_references,
    function_name,
    ret
)
    print("TEST REGION TEXT", region:get_text())
    return Config.get_config().code_generation[lang].extract_function({
        args = vim.tbl_keys(selected_local_references),
        body = region:get_text(),
        name = function_name,
        ret = ret,
    })
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

local function get_extract_setup_pipeline(bufnr)
    return Pipeline
        :from_task(refactor_setup(bufnr, Config.get_config()))
        :add_task(selection_setup)
        :add_task(get_selected_local_defs)
        :add_task(get_input("106: Extract Function Name > "))
end

M.extract_to_file = function(bufnr)
    bufnr = bufnr or vim.fn.bufnr(vim.fn.bufname())
    get_extract_setup_pipeline(bufnr)
        :add_task(get_input("106: File Name > "))
        :add_task(create_file.from_input(2))
        :add_task(function(refactor)
            local selected_local_references = get_selected_local_references(
                refactor
            )
            local function_name = refactor.input[1]
            local extract_function = get_code(
                refactor.lang,
                refactor.region,
                selected_local_references,
                function_name,
                "fill_me"
            )

            refactor.text_edits = {
                {
                    region = utils.region_above_node(refactor.scope),
                    text = extract_function.create,
                    bufnr = refactor.buffers[2],
                },
                {
                    region = refactor.region,
                    text = extract_function.call,
                },
            }

            return true, refactor
        end)
        :after(helpers.create_post_refactor_tasks())
        :run()
end

M.extract = function(bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    get_extract_setup_pipeline(bufnr)
        :add_task(function(refactor)
            local selected_local_references = get_selected_local_references(
                refactor
            )
            local function_name = refactor.input[1]
            local extract_function = get_code(
                refactor.lang,
                refactor.region,
                selected_local_references,
                function_name,
                "fill_me"
            )

            refactor.text_edits = {
                {
                    region = utils.region_above_node(refactor.scope),
                    text = extract_function.create,
                },
                {
                    region = refactor.region,
                    text = extract_function.call,
                },
            }

            return true, refactor
        end)
        :after(helpers.create_post_refactor_tasks())
        :run()
end

return M
