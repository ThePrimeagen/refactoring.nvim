local get_selected_locals = require("refactoring.refactor.get_selected_locals")
local utils = require("refactoring.utils")
local Pipeline = require("refactoring.pipeline")
local selection_setup = require("refactoring.tasks.selection_setup")

local refactor_setup = require("refactoring.tasks.refactor_setup")
local get_input = require("refactoring.get_input")
local create_file = require("refactoring.tasks.create_file")
local post_refactor = require("refactoring.tasks.post_refactor")
local Config = require("refactoring.config")
local Query2 = require("refactoring.query2")
local Query = require("refactoring.query")

local M = {}

-- 1.  We need definition set of potential captpokiWured variables

local function get_extract_setup_pipeline(bufnr)
    return Pipeline
        :from_task(refactor_setup(bufnr, Config.get_config()))
        :add_task(selection_setup)
end

--
--
local function extract_setup(refactor)
    local function_name = get_input("106: Extract Function Name > ")
    assert(function_name ~= "", "Error: Must provide function name")

    local function_body = refactor.region:get_text()
    local args = vim.fn.sort(vim.tbl_keys(get_selected_locals(refactor)))

    local region_vars = utils.region_intersect(
        refactor.ts:local_declarations(refactor.scope), refactor.region)

    region_vars = vim.tbl_map(function(node)
        return refactor.query:pluck_by_capture(node, Query.query_type.LocalVarName)[1]
    end, region_vars)

    region_vars = vim.tbl_filter(function(node)
        return node
    end, region_vars)

    local refs = Query2.get_references(refactor.scope, refactor.locals)
    refs = utils.after_region(refs, refactor.region)

    local region_var_map = utils.node_text_to_set(region_vars)

    local ref_map = utils.node_text_to_set(refs)
    local return_vals = utils.table_key_intersect(region_var_map, ref_map)

    if utils.table_has_keys(return_vals) then
        table.insert(function_body, refactor.code["return"](vim.tbl_keys(return_vals)))
    end

    local function_code = refactor.code["function"]({
        name = function_name,
        args = args,
        body = function_body,
    })

    refactor.text_edits = {
        -- TODO: First text edit is causing cursor issues
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
end

M.extract_to_file = function(bufnr)
    bufnr = bufnr or vim.fn.bufnr(vim.fn.bufname())
    get_extract_setup_pipeline(bufnr)
        :add_task(create_file.from_input)
        :add_task(function(refactor)
            extract_setup(refactor)
            return true, refactor
        end)
        :after(post_refactor)
        :run()
end

M.extract = function(bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    get_extract_setup_pipeline(bufnr)
        :add_task(function(refactor)
            extract_setup(refactor)
            return true, refactor
        end)
        :after(post_refactor)
        :run()
end

return M
