local utils = require("refactoring.utils")
local Pipeline = require("refactoring.pipeline")
local selection_setup = require("refactoring.tasks.selection_setup")
local ensure_code_gen = require("refactoring.tasks.ensure_code_gen")
local code_utils = require("refactoring.code_generation.utils")
local Region = require("refactoring.region")
local Point = require("refactoring.point")
local lsp_utils = require("refactoring.lsp_utils")

local refactor_setup = require("refactoring.tasks.refactor_setup")
local get_input = require("refactoring.get_input")
local create_file = require("refactoring.tasks.create_file")
local post_refactor = require("refactoring.tasks.post_refactor")
local indent = require("refactoring.indent")

local M = {}

-- 1.  We need definition set of potential captured variables

local function get_extract_setup_pipeline(bufnr, opts)
    return Pipeline:from_task(refactor_setup(bufnr, opts))
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
    local function_return_type =
        get_input("106: Extract Function return type > ")
    if function_return_type == "" then
        function_return_type = code_utils.default_func_return_type()
    end
    return function_return_type
end

local function get_function_param_types(refactor, args)
    local args_types = {}
    local parameter_arg_types =
        refactor.ts:get_local_parameter_types(refactor.scope)
    for _, arg in pairs(args) do
        local function_param_type
        local curr_arg = refactor.ts.get_arg_type_key(arg)

        if parameter_arg_types[curr_arg] ~= nil then
            function_param_type = parameter_arg_types[curr_arg]
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
        args_types[curr_arg] = function_param_type
    end

    return args_types
end

local function get_func_header_prefix(refactor)
    local ident_width = indent.buf_indent_width(refactor.bufnr)
    local scope_region = Region:from_node(refactor.scope, refactor.bufnr)
    local scope_start_col = scope_region.start_col
    local baseline_indent = math.floor(scope_start_col / ident_width)
    return indent.indent(baseline_indent, refactor.bufnr)
end

local function get_first_node_row(node)
    local start_row, _, _, _ = node:range()
    local first = node
    while true do
        local parent = first:parent()
        if parent == nil then
            break
        end
        local parent_row, _, _, _ = parent:range()
        if parent_row ~= start_row then
            break
        end
        first = parent
    end
    return first, start_row
end

local function get_indent_prefix(refactor)
    local ident_width = indent.buf_indent_width(refactor.bufnr)
    local first_node_row, _ = get_first_node_row(refactor.scope)
    local scope_region = Region:from_node(first_node_row, refactor.bufnr)
    local scope_start_col = scope_region.start_col
    local baseline_indent = math.floor(scope_start_col / ident_width)
    local total_indents = baseline_indent + 1
    refactor.cursor_col_adjustment = total_indents * ident_width
    return indent.indent(total_indents, refactor.bufnr)
end

---@param function_params table
---@param has_return_vals boolean
---@param refactor Refactor
local function indent_func_code(function_params, has_return_vals, refactor)
    if refactor.ts:is_indent_scope(refactor.scope) then
        -- Indent func header
        local func_header_indent = get_func_header_prefix(refactor)
        function_params.func_header = func_header_indent
    end

    -- Removing indent_chars up to initial indent
    -- Not removing indent for return statement like rest of func body
    local loop_len = #function_params.body + 1
    if has_return_vals then
        loop_len = loop_len - 1
    end
    local i = 1
    while i < loop_len do
        function_params.body[i] = string.sub(
            function_params.body[i],
            refactor.whitespace.func_call
                    * indent.buf_indent_width(refactor.bufnr)
                + 1,
            #function_params.body[i]
        )
        i = i + 1
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
local function get_func_params(extract_params, refactor)
    local func_params = {
        name = extract_params.function_name,
        args = extract_params.args,
        body = extract_params.function_body,
        scope_type = extract_params.scope_type,
    }

    if refactor.ts.require_param_types then
        func_params.args_types =
            get_function_param_types(refactor, func_params.args)
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
    local func_params = get_func_params(extract_params, refactor)

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

--- @param refactor Refactor
--- @param extract_params table
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

    -- in some languages (like typescript and javascript), you can return
    -- multiple values in an object, but treesitter still sees that as multiple
    -- values instead of just one object, which causes odd behaviour
    local exception_languages = {
        typescript = true,
        javascript = true,
    }

    if extract_params.has_return_vals then
        if
            #extract_params.return_vals > 1
            and exception_languages[refactor.filetype] == nil
        then
            func_call.text = refactor.code.constant({
                multiple = true,
                identifiers = extract_params.return_vals,
                values = { func_call.text },
            })
        else
            func_call.text = refactor.code.constant({
                name = extract_params.return_vals,
                value = func_call.text,
            })
        end
    else
        func_call.text = refactor.code.terminate(func_call.text)
    end

    if
        refactor.ts:allows_indenting_task()
        and refactor.ts:is_indent_scope(refactor.scope)
    then
        local indent_whitespace =
            indent.indent(refactor.whitespace.func_call, refactor.bufnr)
        local func_call_with_indent = {}
        func_call_with_indent[1] = indent_whitespace
        func_call_with_indent[2] = func_call.text
        func_call.text = table.concat(func_call_with_indent, "")
    end

    func_call.add_newline = false

    return func_call
end

local function is_comment_or_decorator_node(node)
    if node == nil then
        return false
    end

    local comment_and_decorator_node_types = {
        "comment",
        "block_comment",
        "decorator",
    }

    for _, node_type in ipairs(comment_and_decorator_node_types) do
        if node_type == node:type() then
            return true
        end
    end

    return false
end

local function get_non_comment_region_above_node(refactor)
    local scope = get_first_node_row(refactor.scope)

    local prev_sibling = scope:prev_named_sibling()
    if is_comment_or_decorator_node(prev_sibling) then
        local start_row
        while true do
            -- Only want first value
            start_row = prev_sibling:range()
            local temp = prev_sibling:prev_sibling()
            if is_comment_or_decorator_node(temp) then
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

local function get_selected_locals(refactor, is_class)
    local local_defs =
        refactor.ts:get_local_defs(refactor.scope, refactor.region)
    local region_refs =
        refactor.ts:get_region_refs(refactor.scope, refactor.region)

    -- Removing class variables from things being passed to extracted func
    if is_class then
        local class_vars =
            refactor.ts:get_class_vars(refactor.scope, refactor.region)

        if #class_vars > 0 then
            for _, class_var in ipairs(class_vars) do
                for i, node in ipairs(local_defs) do
                    if node == class_var then
                        table.remove(local_defs, i)
                        break
                    end
                end
            end
        end
    end

    local local_def_map = utils.node_text_to_set(local_defs)
    local region_refs_map = utils.node_text_to_set(region_refs)
    return utils.table_key_intersect(local_def_map, region_refs_map)
end

--- @param refactor Refactor
---@return boolean, Refactor|string
local function extract_block_setup(refactor)
    local region = Region:from_point(Point:from_cursor(), refactor.bufnr)
    local region_node = region:to_ts_node(refactor.ts:get_root())
    local scope = refactor.ts:get_scope(region_node)
    local block_first_child = refactor.ts:get_function_body(scope)[1]
    local block_last_child = block_first_child -- starting off here, we're going to find it manually

    -- we have to find the last direct sibling manually because raw queries
    -- pick up nested children nodes as well
    while block_last_child:next_named_sibling() do
        block_last_child = block_last_child:next_named_sibling()
    end

    local first_line_region = Region:from_node(block_first_child)
    local last_line_region = Region:from_node(block_last_child)

    -- update the region and its node with the block scope found
    region = Region:from_values(
        refactor.bufnr,
        first_line_region.start_row,
        -- The Tresitter delimited region never includes the blank spaces
        -- before the first line which causes problems with indentation.
        1,
        last_line_region.end_row,
        last_line_region.end_col
    )
    region_node = region:to_ts_node(refactor.ts:get_root())

    refactor.region = region
    refactor.region_node = region_node
    refactor.scope = scope
    refactor.whitespace.highlight_start = vim.fn.indent(region.start_row)
    refactor.whitespace.highlight_end = vim.fn.indent(region.end_row)

    if refactor.scope == nil then
        return false, "Scope is nil"
    end

    return true, refactor
end

--- @param refactor Refactor
local function extract_setup(refactor)
    local function_name = get_input("106: Extract Function Name > ")
    assert(function_name ~= "", "Error: Must provide function name")
    local function_body = refactor.region:get_text()

    -- NOTE: How do we think about this if we have to pass through multiple
    -- functions (method extraction)
    local is_class = refactor.ts:is_class_function(refactor.scope)
    local args =
        vim.fn.sort(vim.tbl_keys(get_selected_locals(refactor, is_class)))

    local first_line = function_body[1]

    if refactor.ts:allows_indenting_task() then
        refactor.whitespace.func_call =
            indent.line_indent_amount(first_line, refactor.bufnr)
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
        scope_type = refactor.scope:type(),
    }
    local function_code = get_function_code(refactor, extract_params)
    local func_call = get_func_call(refactor, extract_params)

    local region_above_scope = get_non_comment_region_above_node(refactor)
    local extract_function

    if is_class then
        extract_function = lsp_utils.insert_new_line_text(
            region_above_scope,
            function_code,
            { below = true }
        )
    else
        extract_function = {
            region = get_non_comment_region_above_node(refactor),
            text = function_code,
            bufnr = refactor.buffers[2],
        }
    end

    -- NOTE: there is going to be a bunch of edge cases we haven't thought
    -- about
    refactor.text_edits = {
        extract_function,
        func_call,
    }
end

--- @alias code_gen
--- | '"return"'
--- | '"pack"'
--- | '"call_function"'
--- | '"constant"'
--- | '"function"'
--- | '"function_return"'
--- | '"terminate"'

--- @type code_gen[]
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

--- @alias class_code_gen
--- | '"class_function"'
--- | '"class_function_return"'
--- | '"call_class_function"'

--- @type class_code_gen[]
local class_code_gen_list = {
    "class_function",
    "class_function_return",
    "call_class_function",
}

--- @param refactor Refactor
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

    return ensure_code_gen(refactor, list)
end

M.extract_to_file = function(bufnr, opts)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    get_extract_setup_pipeline(bufnr, opts)
        :add_task(function(refactor)
            return ensure_code_gen_106(refactor)
        end)
        :add_task(create_file.from_input)
        :add_task(function(refactor)
            extract_setup(refactor)
            return true, refactor
        end)
        :after(post_refactor.no_cursor_post_refactor)
        :run()
end

M.extract = function(bufnr, opts)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    get_extract_setup_pipeline(bufnr, opts)
        :add_task(function(refactor)
            return ensure_code_gen_106(refactor)
        end)
        :add_task(function(refactor)
            if refactor.region:is_empty() then
                error(
                    "Current selected region is empty, have to provide a non empty region to perform a extract func operation"
                )
            end
            return true, refactor
        end)
        :add_task(function(refactor)
            extract_setup(refactor)
            return true, refactor
        end)
        :after(post_refactor.post_refactor)
        :run()
end

M.extract_block = function(bufnr, opts)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    Pipeline:from_task(refactor_setup(bufnr, opts))
        :add_task(
            --- @param refactor Refactor
            function(refactor)
                return ensure_code_gen_106(refactor)
            end
        )
        :add_task(
            --- @param refactor Refactor
            function(refactor)
                return extract_block_setup(refactor)
            end
        )
        :add_task(
            --- @param refactor Refactor
            function(refactor)
                extract_setup(refactor)
                return true, refactor
            end
        )
        :after(post_refactor.post_refactor)
        :run()
end

M.extract_block_to_file = function(bufnr, opts)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    Pipeline:from_task(refactor_setup(bufnr, opts))
        :add_task(
            --- @param refactor Refactor
            function(refactor)
                return ensure_code_gen_106(refactor)
            end
        )
        :add_task(function(refactor)
            return extract_block_setup(refactor)
        end)
        :add_task(create_file.from_input)
        :add_task(function(refactor)
            extract_setup(refactor)
            return true, refactor
        end)
        :after(post_refactor.no_cursor_post_refactor)
        :run()
end

return M
