local get_selected_locals = require("refactoring.refactor.get_selected_locals")
local utils = require("refactoring.utils")
local Pipeline = require("refactoring.pipeline")
local selection_setup = require("refactoring.tasks.selection_setup")
local ensure_code_gen = require("refactoring.tasks.ensure_code_gen")
local code_utils = require("refactoring.code_generation.utils")

local refactor_setup = require("refactoring.tasks.refactor_setup")
local get_input = require("refactoring.get_input")
local create_file = require("refactoring.tasks.create_file")
local post_refactor = require("refactoring.tasks.post_refactor")

local M = {}

-- 1.  We need definition set of potential captured variables

local function get_extract_setup_pipeline(bufnr, opts)
    return Pipeline
        :from_task(refactor_setup(bufnr, opts))
        :add_task(selection_setup)
end

--

local function get_return_vals(refactor)
    local region_vars = utils.region_intersect(
        refactor.ts:get_local_declarations(refactor.scope),
        refactor.region
    )

    region_vars = vim.tbl_map(function(node)
        return refactor.ts:get_local_var_names(node)[1]
    end, region_vars)

    region_vars = vim.tbl_filter(function(node)
        return node
    end, region_vars)

    local refs = refactor.ts:get_references(refactor.scope)
    refs = utils.after_region(refs, refactor.region)

    local region_var_map = utils.node_text_to_set(region_vars)

    local ref_map = utils.node_text_to_set(refs)
    local return_vals = vim.fn.sort(
        vim.tbl_keys(utils.table_key_intersect(region_var_map, ref_map))
    )

    return return_vals
end

local function get_function_return_type()
    local function_return_type = get_input(
        "106: Extract Function return type > "
    )
    if function_return_type == "" then
        function_return_type = code_utils.default_func_return_type()
    end
    return function_return_type
end

-- TODO: update this if you can find some of the variable values
-- Next to find local defintion var values
local function get_function_param_types(refactor, args)
    local args_types = {}
    local parameter_arg_types = refactor.ts:get_local_parameter_types(
        refactor.scope
    )
    for _, arg in pairs(args) do
        local function_param_type
        if parameter_arg_types[arg] ~= nil then
            function_param_type = parameter_arg_types[arg]
        elseif
            refactor.config:get_prompt_func_param_type(refactor.filetype)
        then
            function_param_type = get_input(
                string.format("106: Extract Function param type for %s > ", arg)
            )

            if function_param_type == "" then
                function_param_type = code_utils.default_func_param_type()
            end
        else
            function_param_type = code_utils.default_func_param_type()
        end
        args_types[arg] = function_param_type
    end
    return args_types
end

local function get_function_code(refactor, extract_params)
    local function_code
    -- TODO: Make this an object with getters/setters so that it's better
    -- documented
    local function_params = {
        name = extract_params.function_name,
        args = extract_params.args,
        body = extract_params.function_body,
    }

    if refactor.ts.require_param_types then
        function_params.args_types = get_function_param_types(
            refactor,
            function_params.args
        )
    end

    if
        extract_params.has_return_vals
        and refactor.config:get_prompt_func_return_type(refactor.filetype)
    then
        function_params.return_type = get_function_return_type()
    end

    if extract_params.is_class and extract_params.has_return_vals then
        function_params["className"] = refactor.ts:get_class_name(
            refactor.scope
        )
        function_code = refactor.code.class_function_return(function_params)
    elseif extract_params.is_class then
        function_params["className"] = refactor.ts:get_class_name(
            refactor.scope
        )
        function_code = refactor.code.class_function(function_params)
    elseif extract_params.has_return_vals then
        function_code = refactor.code.function_return(function_params)
    else
        function_code = refactor.code["function"](function_params)
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
                class_type = refactor.ts:get_class_type(refactor.scope),
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

local function get_non_comment_region_above_node(refactor)
    local prev_sibling = refactor.scope:prev_sibling()
    if prev_sibling == nil then
        return utils.region_above_node(refactor.scope)
    end

    if
        prev_sibling:type() == "comment"
        or prev_sibling:type() == "block_comment"
    then
        local start_row
        while true do
            -- Only want first value
            start_row = prev_sibling:range()
            local temp = prev_sibling:prev_sibling()
            if
                temp ~= nil
                and (temp:type() == "comment" or temp:type() == "block_comment")
            then
                -- Only want first value
                local temp_row = temp:range()
                if start_row - temp_row == 1 then
                    prev_sibling = temp
                else
                    break
                end
            else
                break
            end
        end

        if start_row > 0 then
            return utils.region_above_node(prev_sibling)
        else
            return utils.region_above_node(refactor.scope)
        end
    else
        return utils.region_above_node(refactor.scope)
    end
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
            region = get_non_comment_region_above_node(refactor),
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
