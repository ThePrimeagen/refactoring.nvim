local utils = require("refactoring.utils")
local Pipeline = require("refactoring.pipeline")
local selection_setup = require("refactoring.tasks.selection_setup")
local ensure_code_gen = require("refactoring.tasks.ensure_code_gen")
local code_utils = require("refactoring.code_generation.utils")
local Region = require("refactoring.region")

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

local function get_func_header_prefix(refactor)
    local bufnr_shiftwidth = vim.bo.shiftwidth
    print("bufnr_shiftwidth:", bufnr_shiftwidth)
    local scope_region = Region:from_node(refactor.scope, refactor.bufnr)
    local _, scope_start_col, _, _ = scope_region:to_vim()
    local baseline_indent = math.floor(scope_start_col / bufnr_shiftwidth)
    local opts = {
        indent_width = bufnr_shiftwidth,
        indent_amount = baseline_indent,
    }
    return refactor.code.indent(opts)
end

local function get_indent_prefix(refactor)
    local bufnr_shiftwidth = vim.bo.shiftwidth
    local scope_region = Region:from_node(refactor.scope, refactor.bufnr)
    local _, scope_start_col, _, _ = scope_region:to_vim()
    local baseline_indent = math.floor(scope_start_col / bufnr_shiftwidth)
    local total_indents = baseline_indent + 1
    refactor.cursor_col_adjustment = total_indents * bufnr_shiftwidth
    local opts = {
        indent_width = bufnr_shiftwidth,
        indent_amount = total_indents,
    }
    return refactor.code.indent(opts)
end

local function indent_func_code(function_params, has_return_vals, refactor)
    if refactor.ts:is_indent_scope(refactor.scope) then
        -- Indent func header
        local func_header_indent = get_func_header_prefix(refactor)
        function_params.func_header = func_header_indent
    end

    local i
    -- Removing indent_chars up to initial indent
    -- Not removing indent for return statement like rest of func body
    if refactor.indent_chars > 0 then
        local loop_len = #function_params.body + 1
        if has_return_vals then
            loop_len = loop_len - 1
        end
        i = 1
        while i < loop_len do
            function_params.body[i] = string.sub(
                function_params.body[i],
                refactor.indent_chars + 1,
                #function_params.body[i]
            )
            i = i + 1
        end
    end

    local indent_prefix = get_indent_prefix(refactor)
    i = 1
    while i < #function_params.body + 1 do
        if function_params.body[i] ~= "" then
            local temp = {}
            temp[1] = indent_prefix
            temp[2] = function_params.body[i]
            function_params.body[i] = table.concat(temp, "")
        end
        i = i + 1
    end
end

-- TODO: Change name of this, misleading
local function get_func_parms(extract_params, refactor)
    local func_params = {
        name = extract_params.function_name,
        args = extract_params.args,
        body = extract_params.function_body,
    }

    if refactor.ts.require_param_types then
        func_params.args_types = get_function_param_types(
            refactor,
            func_params.args
        )
    end

    if
        extract_params.has_return_vals
        and refactor.config:get_prompt_func_return_type(refactor.filetype)
    then
        func_params.return_type = get_function_return_type()
    end

    -- TODO: Move this to main get_function_code function
    if refactor.ts:allows_indenting_task() then
        indent_func_code(func_params, extract_params.has_return_vals, refactor)
    end
    return func_params
end

local function get_function_code(refactor, extract_params)
    local function_code
    local func_params = get_func_parms(extract_params, refactor)

    if extract_params.is_class then
        func_params.className = refactor.ts:get_class_name(refactor.scope)
        if extract_params.has_return_vals then
            function_code = refactor.code.class_function_return(func_params)
        else
            function_code = refactor.code.class_function(func_params)
        end
    elseif extract_params.has_return_vals then
        function_code = refactor.code.function_return(func_params)
    else
        function_code = refactor.code["function"](func_params)
    end
    return function_code
end

local function get_indent_func_call(refactor)
    local temp = {}
    local i = 0
    while i < refactor.indent_chars + 1 do
        temp[i] = refactor.code.indent_char()
        i = i + 1
    end
    return table.concat(temp, "")
end

local function get_func_call(refactor, extract_params)
    local func_call
    if extract_params.is_class then
        func_call = {
            region = refactor.region,
            text = refactor.code.call_class_function({
                name = extract_params.function_name,
                args = extract_params.args,
                class_type = refactor.ts:get_class_type(refactor.scope),
            }),
            add_newline = false,
        }
    else
        func_call = {
            region = refactor.region,
            text = refactor.code.call_function({
                name = extract_params.function_name,
                args = extract_params.args,
            }),
            add_newline = false,
        }
    end

    if extract_params.has_return_vals then
        func_call.text = refactor.code.constant({
            name = extract_params.return_vals,
            value = func_call.text,
        })
    else
        func_call.text = refactor.code.terminate(func_call.text)
    end

    if
        refactor.ts:allows_indenting_task()
        and refactor.ts:is_indent_scope(refactor.scope)
    then
        local indent_whitespace = get_indent_func_call(refactor)
        local func_call_with_indent = {}
        func_call_with_indent[1] = indent_whitespace
        func_call_with_indent[2] = func_call.text
        func_call.text = table.concat(func_call_with_indent, "")
    end
    return func_call
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

local function get_selected_locals(refactor)
    local local_defs = refactor.ts:get_local_defs(
        refactor.scope,
        refactor.region
    )
    local region_refs = refactor.ts:get_region_refs(
        refactor.scope,
        refactor.region
    )
    local local_def_map = utils.node_text_to_set(local_defs)
    local region_refs_map = utils.node_text_to_set(region_refs)
    return utils.table_key_intersect(local_def_map, region_refs_map)
end

local function extract_setup(refactor)
    local function_name = get_input("106: Extract Function Name > ")
    assert(function_name ~= "", "Error: Must provide function name")
    local function_body = refactor.region:get_text()
    local args = vim.fn.sort(vim.tbl_keys(get_selected_locals(refactor)))
    local is_class = refactor.ts:is_class_function(refactor.scope)
    local first_line = function_body[1]

    if refactor.ts:allows_indenting_task() then
        refactor.indent_chars = refactor.code.indent_char_length(first_line)
    end

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
    local func_call = get_func_call(refactor, extract_params)

    refactor.text_edits = {
        {
            region = get_non_comment_region_above_node(refactor),
            text = function_code,
            bufnr = refactor.buffers[2],
        },
        func_call,
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

local class_code_gen_list = {
    "class_function",
    "class_function_return",
    "call_class_function",
}

local indent_code_gen_list = {
    "indent_char_length",
    "indent",
    "indent_char",
}

local function ensure_code_gen_106(refactor)
    local list = {}
    for _, func in ipairs(ensure_code_gen_list) do
        table.insert(list, func)
    end

    if refactor.ts:class_support() then
        for _, func in ipairs(class_code_gen_list) do
            table.insert(list, func)
        end
    end

    if refactor.ts:allows_indenting_task() then
        for _, func in ipairs(indent_code_gen_list) do
            table.insert(list, func)
        end
    end
    return ensure_code_gen(refactor, list)
end

M.extract_to_file = function(bufnr, opts)
    bufnr = bufnr or vim.fn.bufnr(vim.fn.bufname())
    get_extract_setup_pipeline(bufnr, opts)
        :add_task(function(refactor)
            return ensure_code_gen_106(refactor)
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
            return ensure_code_gen_106(refactor)
        end)
        :add_task(function(refactor)
            extract_setup(refactor)
            return true, refactor
        end)
        :after(post_refactor)
        :run()
end

return M
