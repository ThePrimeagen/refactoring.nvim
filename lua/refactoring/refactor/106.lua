local utils = require("refactoring.utils")
local Pipeline = require("refactoring.pipeline")
local selection_setup = require("refactoring.tasks.selection_setup")
local ensure_code_gen = require("refactoring.tasks.ensure_code_gen")
local code_utils = require("refactoring.code_generation.utils")
local Region = require("refactoring.region")
local Point = require("refactoring.point")
local text_edits_utils = require("refactoring.text_edits_utils")
local Query = require("refactoring.query")

local refactor_setup = require("refactoring.tasks.refactor_setup")
local get_input = require("refactoring.get_input")
local create_file = require("refactoring.tasks.create_file")
local post_refactor = require("refactoring.tasks.post_refactor")
local indent = require("refactoring.indent")
local notify = require("refactoring.notify")

local M = {}

-- 1.  We need definition set of potential captured variables

---@param bufnr integer
---@param opts Config
---@return RefactorPipeline
local function get_extract_setup_pipeline(bufnr, opts)
    return Pipeline:from_task(refactor_setup(bufnr, opts))
        :add_task(selection_setup)
end

---@param refactor Refactor
---@return string[]
local function get_return_vals(refactor)
    local local_declarations =
        refactor.ts:get_local_declarations(refactor.scope)

    local region_declarations = vim.iter(local_declarations)
        :filter(function(node)
            return utils.region_intersect(node, refactor.region)
        end)
        :map(
            ---@param node TSNode
            ---@return TSNode
            function(node)
                return refactor.ts:get_local_var_names(node)[1]
            end
        )
        :filter(
            ---@param node TSNode
            function(node)
                return not not node
            end
        )
        :map(
            ---@param node TSNode
            ---@return TSNode
            function(node)
                return utils.node_to_parent_if_needed(refactor, node)
            end
        )
        :totable()

    local refs = vim.iter(refactor.ts:get_references(refactor.scope))
        :filter(function(node)
            return utils.after_region(node, refactor.region)
        end)
        :map(
            ---@param node TSNode
            ---@return TSNode
            function(node)
                return utils.node_to_parent_if_needed(refactor, node)
            end
        )
        :totable()

    local bufnr = refactor.buffers[1]
    local region_var_map = utils.nodes_to_text_set(bufnr, region_declarations)

    local ref_map = utils.nodes_to_text_set(bufnr, refs)
    local return_vals =
        vim.tbl_keys(utils.table_key_intersect(region_var_map, ref_map))
    table.sort(return_vals)

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

---@param refactor Refactor
---@param args string[]
---@return table<string, string|nil>
local function get_function_param_types(refactor, args)
    local args_types = {}

    local local_types = refactor.ts:get_local_types(refactor.scope)

    for _, arg in pairs(args) do
        --- @type string|nil
        local function_param_type
        local curr_arg = refactor.ts.get_arg_type_key(arg)

        if local_types[curr_arg] ~= nil then
            function_param_type = local_types[curr_arg]
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
        --- @type string|nil
        args_types[curr_arg] = function_param_type
    end

    return args_types
end

---@param refactor Refactor
local function get_func_header_prefix(refactor)
    local indent_width = indent.buf_indent_width(refactor.bufnr)
    local scope_region = Region:from_node(refactor.scope, refactor.bufnr)
    local min_indent = math.min(scope_region.end_col, scope_region.start_col)
    local baseline_indent = math.floor(min_indent / indent_width)
    return indent.indent(baseline_indent, refactor.bufnr)
end

---@param refactor Refactor
local function get_indent_prefix(refactor)
    local ident_width = indent.buf_indent_width(refactor.bufnr)
    local first_node_in_row, _ = utils.get_first_node_in_row(refactor.scope)
    local scope_region = Region:from_node(first_node_in_row, refactor.bufnr)
    local scope_start_col = scope_region.start_col
    local baseline_indent = math.floor(scope_start_col / ident_width)
    local total_indents = baseline_indent + 1
    refactor.cursor_col_adjustment = total_indents * ident_width
    return indent.indent(total_indents, refactor.bufnr)
end

---@param function_params func_params
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
    local lines_to_remove = #function_params.body
    if has_return_vals then
        lines_to_remove = lines_to_remove - 1
    end
    indent.lines_remove_indent(
        function_params.body,
        1,
        lines_to_remove,
        refactor.whitespace.func_call,
        refactor.bufnr
    )

    local indent_prefix = get_indent_prefix(refactor)
    for i = 1, #function_params.body do
        if function_params.body[i] ~= "" then
            function_params.body[i] =
                table.concat({ indent_prefix, function_params.body[i] }, "")
        end
    end
end

---@param extract_params extract_params
---@param refactor Refactor
---@return func_params
local function get_func_params_opts(extract_params, refactor)
    ---@class func_params
    ---@field func_header? string
    ---@field contains_jsx? boolean
    ---@field class_name? string
    ---@field visibility? string
    local func_params = {
        name = extract_params.function_name,
        args = extract_params.args,
        body = extract_params.function_body,
        scope_type = extract_params.scope_type,
        ---@type string
        region_type = refactor.region:to_ts_node(refactor.ts:get_root()):type(),
        visibility = refactor.config:get_visibility_for(refactor.filetype),
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

---@param refactor Refactor
---@param extract_params extract_params
---@return string
local function get_function_code(refactor, extract_params)
    --- @type string
    local function_code
    local func_params_opts = get_func_params_opts(extract_params, refactor)

    if extract_params.is_class then
        func_params_opts.class_name = refactor.ts:get_class_name(refactor.scope)
        func_params_opts.visibility =
            refactor.config:get_visibility_for(refactor.filetype)
        if extract_params.has_return_vals then
            function_code =
                refactor.code.class_function_return(func_params_opts)
        else
            function_code = refactor.code.class_function(func_params_opts)
        end
    elseif extract_params.has_return_vals then
        function_code = refactor.code.function_return(func_params_opts)
    else
        function_code = refactor.code["function"](func_params_opts)
    end
    return function_code
end

--- @param refactor Refactor
--- @param extract_params extract_params
---@return string
local function get_func_call(refactor, extract_params)
    --- @type string
    local func_call
    if extract_params.is_class then
        func_call = refactor.code.call_class_function({
            name = extract_params.function_name,
            args = extract_params.args,
            class_type = refactor.ts:get_class_type(refactor.scope),
        })
    else
        -- TODO (TheLeoP): jsx specific logic
        local ok, ocurrences = pcall(
            Query.find_occurrences,
            refactor.scope,
            "(jsx_element) @tmp_capture",
            refactor.bufnr
        )
        local contains_jsx = ok and #ocurrences > 0
        func_call = refactor.code.call_function({
            name = extract_params.function_name,
            args = extract_params.args,
            region_type = extract_params.region_type,
            contains_jsx = contains_jsx,
        })
    end

    -- in some languages (like typescript and javascript), you can return
    -- multiple values in an object, but treesitter still sees that as multiple
    -- values instead of just one object, which causes odd behaviour
    local exception_languages = {
        typescript = true,
        javascript = true,
        typescriptreact = true,
    }

    if extract_params.has_return_vals then
        if
            #extract_params.return_vals > 1
            and exception_languages[refactor.filetype] == nil
        then
            func_call = refactor.code.constant({
                multiple = true,
                identifiers = extract_params.return_vals,
                values = { func_call },
            })
        else
            func_call = refactor.code.constant({
                name = extract_params.return_vals,
                value = func_call,
            })
        end
    else
        func_call = refactor.code.terminate(func_call)
    end

    if
        refactor.ts:allows_indenting_task()
        and refactor.ts:is_indent_scope(refactor.scope)
    then
        local indent_amount = indent.buf_indent_amount(
            refactor.region:get_start_point(),
            refactor,
            false,
            refactor.bufnr
        )
        local indent_whitespace = indent.indent(indent_amount, refactor.bufnr)
        func_call = table.concat({ indent_whitespace, func_call }, "")
    end

    return func_call
end

--- @param refactor Refactor
---@return boolean, Refactor|string
local function extract_block_setup(refactor)
    local region = Region:from_point(Point:from_cursor(), refactor.bufnr)
    local region_node = region:to_ts_node(refactor.ts:get_root())
    ---@type boolean, TSNode|nil|string
    local ok, scope = pcall(refactor.ts.get_scope, refactor.ts, region_node)
    if not ok then
        ---@cast scope string
        return ok, scope
    end
    ---@cast scope TSNode

    if scope == nil then
        return false, "Scope is nil. Couldn't find scope for current block"
    end

    local ok2, function_body =
        pcall(refactor.ts.get_function_body, refactor.ts, scope)
    if not ok2 then
        return ok2, function_body
    end
    local block_first_child = function_body[1]
    local block_last_child = function_body[#function_body]

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

    if refactor.scope == nil then
        return false, "Scope is nil"
    end

    return true, refactor
end

--- @param refactor Refactor
--- @return boolean, Refactor|string
local function extract_setup(refactor)
    local function_name = get_input("106: Extract Function Name > ")
    if not function_name or function_name == "" then
        return false, "Error: Must provide function name"
    end
    local function_body = refactor.region:get_text()

    -- NOTE: How do we think about this if we have to pass through multiple
    -- functions (method extraction)
    local ok, locals = pcall(utils.get_selected_locals, refactor)
    if not ok then
        return ok, locals
    end
    local args = vim.tbl_keys(locals)
    table.sort(args)

    local first_line = function_body[1]

    if refactor.ts:allows_indenting_task() then
        refactor.whitespace.func_call =
            indent.line_indent_amount(first_line, refactor.bufnr)
    end

    local ok2, return_vals = pcall(get_return_vals, refactor)
    if not ok2 then
        return ok2, return_vals
    end
    local has_return_vals = #return_vals > 0
    if has_return_vals then
        table.insert(
            function_body,
            refactor.code["return"](refactor.code.pack(return_vals))
        )
    end

    local is_class = refactor.ts:is_class_function(refactor.scope)

    ---@class extract_params
    local extract_params = {
        return_vals = return_vals,
        has_return_vals = has_return_vals,
        is_class = is_class,
        args = args,
        function_name = function_name,
        function_body = function_body,
        ---@type string
        scope_type = refactor.scope:type(),
        ---@type string
        region_type = refactor.region:to_ts_node(refactor.ts:get_root()):type(),
    }

    local ok3, function_code =
        pcall(get_function_code, refactor, extract_params)
    if not ok3 then
        return ok3, function_code
    end
    local region_above_scope = utils.get_non_comment_region_above_node(refactor)

    ---@type RefactorTextEdit
    local extract_function
    if is_class then
        extract_function = text_edits_utils.insert_new_line_text(
            region_above_scope,
            function_code,
            { below = true, _end = true }
        )
    else
        extract_function = text_edits_utils.insert_new_line_text(
            region_above_scope,
            function_code,
            { below = true }
        )
        --- @type integer
        extract_function.bufnr = refactor.buffers[2]
    end

    refactor.text_edits = {}
    -- NOTE: there is going to be a bunch of edge cases we haven't thought
    -- about
    table.insert(refactor.text_edits, extract_function)

    local lang = vim.treesitter.language.get_lang(refactor.filetype)
    if not lang then
        return false, "Error: Language not found"
    end

    local selected_code = table.concat(refactor.region:get_text(), "\n")
    local parser = vim.treesitter.get_string_parser(selected_code, lang)
    local languagetree = parser:parse()
    local root = languagetree[1]:root()
    local has_error = root:has_error() --[[@as boolean]]

    local ok4, func_call = pcall(get_func_call, refactor, extract_params)
    if not ok4 then
        return ok4, func_call
    end

    -- PHP parser needs the PHP tag to parse code, so it's imposible to generate
    -- an adecuate sexpr with only the selected text
    --
    -- C# parser parses expresions without a surrounding scope as childs of the
    -- `global_statement` node, so it's imposibble to match them against
    -- non-global statements
    --
    -- TSX/JSX parser parses isolated tags as having an expression parent
    local number_of_function_calls = 0
    if
        not has_error
        and refactor.filetype ~= "php"
        and refactor.filetype ~= "cs"
        and refactor.filetype ~= "typescriptreact"
        and refactor.filetype ~= "javascriptreact"
    then
        --- @type string[]
        local body_sexprs = {}
        do
            local i = 1
            for node in root:iter_children() do
                table.insert(body_sexprs, node:sexpr() .. " @temp" .. i)
                i = i + 1
            end
        end

        local body_sexpr = "(" .. table.concat(body_sexprs, " . ") .. ")"
        local query = vim.treesitter.query.parse(lang, body_sexpr)

        for _, match in query:iter_matches(refactor.root, refactor.bufnr, 0, -1) do
            if match then
                local first = match[1] --[[@as TSNode]]
                local last = match[#match] --[[@as TSNode]]
                local start_row, _, _, _ = first:range()
                local _, _, end_row, end_col = last:range()

                local region = Region:from_values(
                    refactor.bufnr,
                    start_row + 1,
                    1,
                    end_row + 1,
                    end_col
                )

                if
                    table.concat(region:get_text(), "")
                    == table.concat(refactor.region:get_text(), "")
                then
                    number_of_function_calls = number_of_function_calls + 1
                    table.insert(
                        refactor.text_edits,
                        text_edits_utils.replace_text(region, func_call)
                    )
                end
            end
        end
    else
        number_of_function_calls = 1
        table.insert(
            refactor.text_edits,
            text_edits_utils.replace_text(refactor.region, func_call)
        )
    end
    refactor.success_message = ("Function extracted. Inlined %s function calls"):format(
        number_of_function_calls
    )

    return true, refactor
end

local ensure_code_gen_list = {
    "return",
    "pack",
    "call_function",
    "constant",
    "function",
    "function_return",
    "terminate",
}

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

---@param bufnr integer
---@param opts Config
M.extract_to_file = function(bufnr, opts)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    get_extract_setup_pipeline(bufnr, opts)
        :add_task(ensure_code_gen_106)
        :add_task(create_file.from_input)
        :add_task(extract_setup)
        :after(post_refactor.no_cursor_post_refactor)
        :run(nil, notify.error)
end

---@param bufnr integer
---@param opts Config
M.extract = function(bufnr, opts)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    get_extract_setup_pipeline(bufnr, opts)
        :add_task(ensure_code_gen_106)
        :add_task(
            ---@param refactor Refactor
            ---@return boolean, Refactor|string
            function(refactor)
                if refactor.region:is_empty() then
                    return false,
                        "Current selected region is empty, have to provide a non empty region to perform a extract func operation"
                end
                return true, refactor
            end
        )
        :add_task(extract_setup)
        :after(post_refactor.post_refactor)
        :run(nil, notify.error)
end

---@param bufnr integer
---@param opts Config
M.extract_block = function(bufnr, opts)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    Pipeline:from_task(refactor_setup(bufnr, opts))
        :add_task(ensure_code_gen_106)
        :add_task(extract_block_setup)
        :add_task(extract_setup)
        :after(post_refactor.post_refactor)
        :run(nil, notify.error)
end

---@param bufnr integer
---@param opts Config
M.extract_block_to_file = function(bufnr, opts)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    Pipeline:from_task(refactor_setup(bufnr, opts))
        :add_task(ensure_code_gen_106)
        :add_task(extract_block_setup)
        :add_task(create_file.from_input)
        :add_task(extract_setup)
        :after(post_refactor.no_cursor_post_refactor)
        :run(nil, notify.error)
end

return M
