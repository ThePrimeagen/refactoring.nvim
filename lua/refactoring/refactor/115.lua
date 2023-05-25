local Pipeline = require("refactoring.pipeline")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local post_refactor = require("refactoring.tasks.post_refactor")
local ts = require("refactoring.ts")
local Region = require("refactoring.region")
local lsp_utils = require("refactoring.lsp_utils")
local ts_utils = require("nvim-treesitter.ts_utils")
local utils = require("refactoring.utils")

local function dump(o)
    if type(o) == "table" then
        local s = "{ "
        for k, v in pairs(o) do
            if type(k) ~= "number" then
                k = '"' .. k .. '"'
            end
            s = s .. "[" .. k .. "] = " .. dump(v) .. ","
        end
        return s .. "} "
    else
        return tostring(o)
    end
end

local function dumpcode(o)
    if type(o) == "table" then
        local out = {}
        for idx, identifier in pairs(o) do
            local region = Region:from_node(identifier)
            local parameter_list = region:get_text()
            table.insert(out, idx, parameter_list)
        end
        return dump(out)
    else
        local region = Region:from_node(o)
        local parameter_list = region:get_text()
        return dump(parameter_list)
    end
end

local function pdebug(o)
    print("INLINE_FUNC_DEBUG")
    print(dump(o))
    print("")
end


local M = {}

local function get_inline_setup_pipeline(bufnr, opts)
    return Pipeline:from_task(refactor_setup(bufnr, opts))
    -- :add_task(selection_setup)
end

local function determine_declarator_node(refactor, bufnr)
    -- only deal with first declaration
    local declarator_node = refactor.ts:local_declarations_under_cursor(
        refactor.scope,
        refactor.region
    )

    if declarator_node then
        return declarator_node
    else
        local current_node = ts.get_node_at_cursor(0)
        local declaration = ts.find_declaration(current_node, bufnr)
        if declaration ~= nil then
            return declaration
        end

        local definition = ts.find_definition(current_node, bufnr)
        declarator_node = refactor.ts.get_container(definition, refactor.ts.function_declaration)
        return declarator_node
    end
end

local function is_processed(list, item)
    for _, value in ipairs(list) do
        if value == item then
            return true
        end
    end
    return false
end

local function get_function_arguments(refactor, declarator_node, bufnr)
    local args = {}
    for _, value in ipairs(refactor.ts:loop_thru_nodes(declarator_node:parent(), refactor.ts.function_args)) do
        table.insert(args, vim.treesitter.get_node_text(value, bufnr))
    end
    return args
end

local function get_used_function_definition(refactor, declarator_node, bufnr)
    for _, node in ipairs(refactor.ts:get_function_body(declarator_node:parent())) do
        local curr_scope = refactor.ts:get_scope(node)
        local curr_region = Region:from_node(node)
        local local_defs = refactor.ts:get_local_defs(curr_scope, curr_region)
        local region_refs = refactor.ts:get_region_refs(curr_scope, curr_region)
        local local_def_map = utils.node_text_to_set(bufnr, local_defs)
        local region_refs_map = utils.node_text_to_set(bufnr, region_refs)
        return vim.fn.sort(vim.tbl_keys(utils.table_key_intersect(local_def_map, region_refs_map)))
    end
    return {}
end

local function get_function_calls(refactor, declarator_node, args)
    local function_calls = {}
    if #args == 0 then
        return function_calls
    end

    for _, value in ipairs(refactor.ts:get_statements(declarator_node:parent())) do
        local region

        local class_type = value:child(0):child(0)
        region = Region:from_node(class_type)
        local class_type_text = region:get_text()[1]

        local class_accesor = value:child(0):child(1)
        region = Region:from_node(class_accesor)
        local class_accessor_text = region:get_text()[1]

        local name = value:child(0):child(2)
        region = Region:from_node(name)
        local name_text = region:get_text()[1]

        -- TODO: fix indent
        for _, arg in ipairs(args) do
            local function_call = refactor.code.call_function({
                name = "\t" .. class_type_text .. class_accessor_text .. name_text,
                args = { arg },
            })
            table.insert(function_calls, function_call)
        end
    end
    return function_calls
end


local function get_inlined_params(refactor, ref, declarator_args, bufnr)
    local params = {}
    for _, node in ipairs(ts_utils.get_named_children(ref:parent())) do
        if node:type() == "argument_list" then
            for index, argument in ipairs(ts_utils.get_named_children(node)) do
                local fix_indent = ""
                if index > 1 then
                    fix_indent = "\t"
                end

                local inlined_constant = refactor.code.constant({
                    name = declarator_args[index],
                    value = vim.treesitter.get_node_text(argument, bufnr),
                })
                table.insert(params, fix_indent .. inlined_constant)
            end
        end
    end
    return params
end

local function inline_func_setup(refactor, bufnr)
    local text_edits = {}

    -- TODO: aqui tengo que ingeniarme algo para detectar si es un declaration
    -- o no, si tiene returns o no, y si tiene params (has_params, has_returns, has_algo_mas?)
    local declarator_node = determine_declarator_node(refactor, bufnr)
    -- print(type(declarator_node))

    local statements = {}
    for _, statement in ipairs(refactor.ts:get_statements(declarator_node)) do
        if statement:type() == "call_expression" then
            table.insert(statements, statement)
        end
    end


    if #statements > 0 then
        -- build the returned variable names from the caller
        local returned_variable_names = {}
        local identifiers = refactor.ts:get_local_var_names(declarator_node)
        for _, identifier in ipairs(identifiers) do
            table.insert(returned_variable_names, vim.treesitter.get_node_text(identifier, bufnr))
        end

        -- find the new declarator node
        local new_declarator_node
        for _, statement in ipairs(statements) do
            local declaration = ts.find_declaration(statement:child(0), bufnr)
            if declaration then
                new_declarator_node = declaration
            end
        end

        -- build the returned values table from the function body
        local returned_values = {}
        if new_declarator_node ~= nil then
            for _, statement in ipairs(refactor.ts:get_statements(new_declarator_node:parent())) do
                -- TODO: ugly as hell
                if statement:type() == "return_statement" then
                    if statement:child(1) then
                        local return_value = {}
                        local idx = 0
                        while type(return_value) ~= nil do
                            return_value = statement:child(1):child(idx)
                            if return_value == nil then
                                break
                            end


                            local value = vim.treesitter.get_node_text(return_value, bufnr)
                            if value ~= "," then
                                table.insert(returned_values, value)
                            end
                            idx = idx + 1
                        end
                    end
                end
            end
        end

        local variable_declaration = {}
        for index, _ in ipairs(returned_variable_names) do
            local fix_indent = ""
            if index > 1 then
                fix_indent = "\t"
            end

            local param = refactor.code.constant({
                name = fix_indent .. returned_variable_names[index],
                value = returned_values[index],
            })
            table.insert(variable_declaration, index, param)
        end


        for _, statement in ipairs(statements) do
            -- Insert each param as an inlined param (constant)
            for index, _ in ipairs(returned_variable_names) do
                local insert_text = lsp_utils.insert_text(Region:from_node(statement:parent():parent(), bufnr),
                    variable_declaration[index])
                table.insert(text_edits, insert_text)
            end

            -- delete the current function
            local delete_text = lsp_utils.delete_text(Region:from_node(statement:parent():parent(), bufnr))
            table.insert(text_edits, delete_text)
        end

        -- detele the original function
        table.insert(
            text_edits,
            lsp_utils.delete_text(Region:from_node(new_declarator_node:parent(), bufnr))
        )
    end


    local references =
        ts.find_references(declarator_node, refactor.scope, bufnr, declarator_node)
    -- print("references")
    -- print(dump(references))

    if #references < 2 and #statements == 0 then
        error("Error: no function usages to inline")
        return
    end

    local declarator_args = get_function_arguments(refactor, declarator_node, bufnr)
    -- print("declarator_args")
    -- print(dump(declarator_args))
    local used_args = get_used_function_definition(refactor, declarator_node, bufnr)
    -- print("used_args")
    -- print(vim.inspect(used_args))
    local function_calls = get_function_calls(refactor, declarator_node, used_args)
    -- print("function_calls")
    -- print(dump(function_calls))

    local processed = {}
    if #references > 0 then
        for _, ref in ipairs(references) do
            if not is_processed(processed, ref) then
                if #declarator_args > 0 then
                    local params = get_inlined_params(refactor, ref, declarator_args, bufnr)
                    for _, param in ipairs(params) do
                        -- Insert each param as an inlined param (constant)
                        local insert_text = lsp_utils.insert_text(Region:from_node(ref:parent(), bufnr), param)
                        table.insert(text_edits, insert_text)
                    end

                    -- local func_call = refactor.code.go_call_class_func({ class_type = 'fmt', name = 'Errorf', args = args, })
                    -- local func_call = refactor.code.call_function({ name = '\tfmt.Errorf', args = args, })
                    for index, function_call in ipairs(function_calls) do
                        local fix_new_line = ""
                        if #function_calls > 1 and index < #function_calls then
                            fix_new_line = "\n"
                        end

                        -- Insert function call
                        local insert_text = lsp_utils.insert_text(Region:from_node(ref:parent(), bufnr),
                            function_call .. fix_new_line)
                        table.insert(text_edits, insert_text)
                    end

                    -- delete the current function
                    local delete_text = lsp_utils.delete_text(Region:from_node(ref:parent(), bufnr))
                    table.insert(text_edits, delete_text)
                else
                    local function_text
                    for _, value in ipairs(refactor.ts:get_function_body(declarator_node:parent())) do
                        function_text = vim.treesitter.get_node_text(value, bufnr)
                    end

                    local lsp_range = ts_utils.node_to_lsp_range(ref:parent())
                    local text_edit = { range = lsp_range, newText = function_text }
                    table.insert(text_edits, text_edit)
                end
                table.insert(processed, ref)
            end
        end
        -- detele the original function
        table.insert(
            text_edits,
            lsp_utils.delete_text(Region:from_node(declarator_node:parent(), bufnr))
        )
    end
    refactor.text_edits = text_edits
end

---@param bufnr number
---@param opts table
function M.inline_func(bufnr, opts)
    get_inline_setup_pipeline(bufnr, opts)
        :add_task(
        --- @param refactor Refactor
            function(refactor)
                inline_func_setup(refactor, bufnr)
                return true, refactor
            end
        )
        :after(post_refactor.post_refactor)
        :run()
end

return M
