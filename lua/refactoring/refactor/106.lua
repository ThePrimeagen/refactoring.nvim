local get_selected_locals = require("refactoring.refactor.get_selected_locals")
local utils = require("refactoring.utils")
local Pipeline = require("refactoring.pipeline")
local selection_setup = require("refactoring.tasks.selection_setup")
local ensure_code_gen = require("refactoring.tasks.ensure_code_gen")

local refactor_setup = require("refactoring.tasks.refactor_setup")
local get_input = require("refactoring.get_input")
local create_file = require("refactoring.tasks.create_file")
local post_refactor = require("refactoring.tasks.post_refactor")
local Query2 = require("refactoring.query2")

local M = {}

-- 1.  We need definition set of potential captpokiWured variables

local function get_extract_setup_pipeline(bufnr, opts)
    return Pipeline
        :from_task(refactor_setup(bufnr, opts))
        :add_task(selection_setup)
end

--

local function get_return_vals(refactor)
    local region_vars = utils.region_intersect(
        refactor.ts:local_declarations(refactor.scope),
        refactor.region
    )

    region_vars = vim.tbl_map(function(node)
        return refactor.ts:local_var_names(node)
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

local function get_function_code(refactor, extract_params)
    local function_code
    if extract_params.is_class and extract_params.has_return_vals then
        function_code = refactor.code.class_function_return({
            name = extract_params.function_name,
            args = extract_params.args,
            body = extract_params.function_body,
            className = refactor.ts:class_name(refactor.scope),
        })
    elseif extract_params.is_class then
        function_code = refactor.code.class_function({
            name = extract_params.function_name,
            args = extract_params.args,
            body = extract_params.function_body,
            className = refactor.ts:class_name(refactor.scope),
        })
    elseif extract_params.has_return_vals then
        function_code = refactor.code.function_return({
            name = extract_params.function_name,
            args = extract_params.args,
            body = extract_params.function_body,
        })
    else
        function_code = refactor.code["function"]({
            name = extract_params.function_name,
            args = extract_params.args,
            body = extract_params.function_body,
        })
    end
    return function_code
end

local function get_value(refactor, extract_params)
    local value
    if extract_params.is_class then
        value = {
            region = refactor.region,
            text = refactor.code.call_class_function({
                name = extract_params.function_name,
                args = extract_params.args,
                class_type = refactor.ts:class_type(refactor.scope),
            }),
            add_newline = false,
        }
    else
        value = {
            region = refactor.region,
            text = refactor.code.call_function({
                name = extract_params.function_name,
                args = extract_params.args,
            }),
            add_newline = false,
        }
    end

    if extract_params.has_return_vals then
        value = {
            region = refactor.region,
            text = refactor.code.constant({
                name = extract_params.return_vals,
                value = value.text,
            }),
            add_newline = false,
        }
    else
        value.text = refactor.code.terminate(value.text)
    end

    return value
end

--
local function extract_setup(refactor)
    local function_name = get_input("106: Extract Function Name > ")
    assert(function_name ~= "", "Error: Must provide function name")
    local function_body = refactor.region:get_text()
    local args = vim.fn.sort(vim.tbl_keys(get_selected_locals(refactor)))
    local is_class = refactor.ts:is_class_function(refactor.scope)

    local return_vals = get_return_vals(refactor)
    local has_return_vals = #return_vals > 0
    if has_return_vals then
        table.insert(
            function_body,
            refactor.code["return"](refactor.code.pack(return_vals))
        )
    end

    local extract_params = {
        return_vals = return_vals,
        has_return_vals = has_return_vals,
        is_class = is_class,
        args = args,
        function_name = function_name,
        function_body = function_body,
    }
    local function_code = get_function_code(refactor, extract_params)
    local value = get_value(refactor, extract_params)

    refactor.text_edits = {
        {
            region = utils.region_above_node(refactor.scope),
            text = function_code,
            bufnr = refactor.buffers[2],
        },
        value,
    }
end

local ensure_code_gen_list = {
    "return",
    "pack",
    "call_function",
    "constant",
    "function",
    "function_return",
    "terminate",
    -- TODO: Should we require these?
    -- "class_function",
    -- "class_function_return",
}

M.extract_to_file = function(bufnr, opts)
    bufnr = bufnr or vim.fn.bufnr(vim.fn.bufname())
    get_extract_setup_pipeline(bufnr, opts)
        :add_task(function(refactor)
            return ensure_code_gen(refactor, ensure_code_gen_list)
        end)
        :add_task(create_file.from_input)
        :add_task(function(refactor)
            extract_setup(refactor)
            return true, refactor
        end)
        :after(post_refactor)
        :run()
end

M.extract = function(bufnr, opts)
    bufnr = bufnr or vim.fn.bufnr()
    get_extract_setup_pipeline(bufnr, opts)
        :add_task(function(refactor)
            return ensure_code_gen(refactor, ensure_code_gen_list)
        end)
        :add_task(function(refactor)
            extract_setup(refactor)
            return true, refactor
        end)
        :after(post_refactor)
        :run()
end

return M
