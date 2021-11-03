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

local function get_return_vals(refactor)
    local region_vars = utils.region_intersect(
        refactor.ts:local_declarations(refactor.scope),
        refactor.region
    )

    region_vars = vim.tbl_map(function(node)
        return refactor.query:pluck_by_capture(
            node,
            Query.query_type.LocalVarName
        )[1]
    end, region_vars)

    region_vars = vim.tbl_filter(function(node)
        return node
    end, region_vars)

    local refs = Query2.get_references(refactor.scope, refactor.locals)
    refs = utils.after_region(refs, refactor.region)

    local region_var_map = utils.node_text_to_set(region_vars)

    local ref_map = utils.node_text_to_set(refs)
    local return_vals = vim.fn.sort(
        vim.tbl_keys(utils.table_key_intersect(region_var_map, ref_map))
    )

    return return_vals
end

--
local function extract_setup(refactor)
    local function_name = get_input("106: Extract Function Name > ")
    assert(function_name ~= "", "Error: Must provide function name")
    local function_body = refactor.region:get_text()
    local args = vim.fn.sort(vim.tbl_keys(get_selected_locals(refactor)))

    local return_vals = get_return_vals(refactor)
    if #return_vals > 0 then
        table.insert(
            function_body,
            refactor.code["return"](refactor.code.pack(return_vals))
        )
    end

    local function_code = refactor.code["function"]({
        name = function_name,
        args = args,
        body = function_body,
        scope = refactor.scope,
        query = refactor.query,
    })

    local value = {
        region = refactor.region,
        text = refactor.code.call_function({
            name = function_name,
            args = args,
            scope = refactor.scope,
            query = refactor.query,
        }),
    }

    if #return_vals > 0 then
        value = {
            region = refactor.region,
            text = refactor.code.constant({
                name = return_vals,
                value = value.text,
            }),
        }
    else
        value.text = refactor.code.terminate(value.text)
    end

    refactor.text_edits = {
        -- TODO: First text edit is causing cursor issues
        {
            region = utils.region_above_node(refactor.scope),
            text = function_code,
            bufnr = refactor.buffers[2],
        },
        value,
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
