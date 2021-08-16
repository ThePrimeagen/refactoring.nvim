local ts_utils = require("nvim-treesitter.ts_utils")
local Query = require("refactoring.query")
local utils = require("refactoring.utils")
local Pipeline = require("refactoring.pipeline")
local selection_setup = require("refactoring.tasks.selection_setup")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local get_input = require("refactoring.get_input")
local create_file = require("refactoring.tasks.create_file")
local post_refactor = require("refactoring.tasks.post_refactor")
local get_selected_local_defs = require(
    "refactoring.tasks.get_selected_local_defs"
)
local Config = require("refactoring.config")

local M = {}

local function get_local_definitions(bufnr, local_defs, function_args)
    local local_def_map = {}

    for _, def in pairs(local_defs) do
        local_def_map[ts_utils.get_node_text(def, bufnr)[1]] = true
    end

    for _, def in pairs(function_args) do
        local_def_map[ts_utils.get_node_text(def, bufnr)[1]] = true
    end

    return local_def_map
end

local function get_selected_local_references(refactor)
    local function_args = refactor.query:pluck_by_capture(
        refactor.scope,
        Query.query_type.FunctionArgument
    )
    local local_def_map = get_local_definitions(
        refactor.bufnr,
        refactor.selected_local_defs,
        function_args
    )

    local local_references = refactor.locals:pluck_by_capture(
        refactor.scope,
        Query.query_type.Reference
    )
    local selected_local_references = {}

    for _, local_ref in pairs(local_references) do
        local local_name = ts_utils.get_node_text(local_ref, refactor.bufnr)[1]
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
end

M.extract_to_file = function(bufnr)
    bufnr = bufnr or vim.fn.bufnr(vim.fn.bufname())
    get_extract_setup_pipeline(bufnr)
        :add_task(create_file.from_input)
        :add_task(function(refactor)
            local selected_local_references = get_selected_local_references(
                refactor
            )
            local function_name = get_input("106: Extract Function Name > ")

            local function_body = refactor.region:get_text()
            table.insert(function_body, refactor.code["return"]("fill_me"))
            local args = vim.fn.sort(vim.tbl_keys(selected_local_references))

            local function_code = refactor.code["function"]({
                name = function_name,
                args = args,
                body = function_body,
            })

            refactor.text_edits = {
                {
                    region = utils.get_top_of_file_region(refactor.scope),
                    text = function_code,
                    bufnr = refactor.buffers[2],
                },
                {
                    region = refactor.region,
                    text = refactor.code.constant({
                        name = "fill_me",
                        value = refactor.code.call_function({
                            name = function_name,
                            args = args,
                        }),
                    }),
                },
            }

            return true, refactor
        end)
        :after(post_refactor)
        :run()
end

M.extract = function(bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    get_extract_setup_pipeline(bufnr)
        :add_task(function(refactor)
            local selected_local_references = get_selected_local_references(
                refactor
            )

            local function_name = get_input("106: Extract Function Name > ")
            assert(function_name ~= "", "Error: Must provide function name")

            local function_body = refactor.region:get_text()
            table.insert(function_body, refactor.code["return"]("fill_me"))
            local args = vim.fn.sort(vim.tbl_keys(selected_local_references))

            local function_code = refactor.code["function"]({
                name = function_name,
                args = args,
                body = function_body,
            })

            refactor.text_edits = {
                {
                    region = utils.region_above_node(refactor.scope),
                    text = function_code,
                    bufnr = refactor.buffers[2],
                },
                {
                    region = refactor.region,
                    text = refactor.code.constant({
                        name = "fill_me",
                        value = refactor.code.call_function({
                            name = function_name,
                            args = args,
                        }),
                    }),
                },
            }

            return true, refactor
        end)
        :after(post_refactor)
        :run()
end

return M
