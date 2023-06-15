local Pipeline = require("refactoring.pipeline")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local post_refactor = require("refactoring.tasks.post_refactor")
local ts = require("refactoring.ts")
local Region = require("refactoring.region")
local lsp_utils = require("refactoring.lsp_utils")
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

local function get_function_declaration(refactor, bufnr)
    local current_node = ts.get_node_at_cursor(0)

    local definition = ts.find_definition(current_node, bufnr)
    local declarator_node = refactor.ts.get_container(definition, refactor.ts.function_scopes)

    local identifier = ts.find_declaration(current_node, bufnr)
    if declarator_node and identifier then
        return declarator_node, identifier
    end
end

local function get_references(refactor, function_declaration)
    return refactor.ts:loop_thru_nodes(function_declaration:parent(), refactor.ts.function_references)
end

local function get_function_returned_values(refactor, function_declaration, bufnr)
    local values = {}
    for _, value in ipairs(refactor.ts:loop_thru_nodes(function_declaration, refactor.ts.return_values)) do
        table.insert(values, vim.treesitter.get_node_text(value, bufnr))
    end
    return values
end

local function get_function_parameter_names(refactor, function_declaration, bufnr)
    local values = {}
    for _, value in ipairs(refactor.ts:loop_thru_nodes(function_declaration:parent(), refactor.ts.function_args)) do
        table.insert(values, vim.treesitter.get_node_text(value, bufnr))
    end
    return values
end

local function get_function_receiver_names(refactor, function_declaration, bufnr)
    local values = {}
    for _, value in ipairs(refactor.ts:loop_thru_nodes(function_declaration:parent(), refactor.ts.local_var_names)) do
        table.insert(values, vim.treesitter.get_node_text(value, bufnr))
    end
    return values
end

local function get_function_arguments(refactor, declarator_node, bufnr)
    local args = {}
    for _, value in ipairs(refactor.ts:loop_thru_nodes(declarator_node:parent(), refactor.ts.caller_args)) do
        table.insert(args, vim.treesitter.get_node_text(value, bufnr))
    end
    return args
end


local function get_function_body(refactor, function_declaration, bufnr)
    local function_body = {}
    local sentences = refactor.ts:get_function_body(function_declaration)
    -- TODO: try to fix indent in one single place
    local new_line = ""
    if #sentences > 1 then
        new_line = "\n"
    end
    for _, sentence in ipairs(sentences) do
        if sentence:type() ~= "return_statement" then
            table.insert(function_body, vim.treesitter.get_node_text(sentence, bufnr) .. new_line)
        end
    end
    return function_body
end

local function get_params_as_constants(refactor, keys, values)
    -- TODO: keys length and values should be the same
    local constants = {}
    for idx, _ in ipairs(keys) do
        table.insert(constants, refactor.code.constant({
            name = keys[idx],
            value = values[idx],
        }))
    end
    return constants
end

local function inlined_sentences_edits(refactor, region, bufnr)
    local text_edits = {}
    local declaration, _ = get_function_declaration(refactor, bufnr)
    local function_declaration_body = get_function_body(refactor, declaration, bufnr)
    for _, sentence in ipairs(function_declaration_body) do
        local text_edit = lsp_utils.insert_text(region, sentence)
        table.insert(text_edits, text_edit)
    end
    return text_edits
end


local function delete_region_edit(region)
    local text_edits = {}
    local delete_text = lsp_utils.delete_text(region)
    table.insert(text_edits, delete_text)
    return text_edits
end


local function inline_func_setup(refactor, bufnr)
    local text_edits = {}

    local function_declaration, _ = get_function_declaration(refactor, bufnr)
    local function_receivers_names = get_function_receiver_names(refactor, function_declaration, bufnr)
    local function_references = get_references(refactor, function_declaration)

    if #function_receivers_names > 0 then
        -- rewrites each parameter with its value in the new place
        for _, reference in ipairs(function_references) do
            local parameter_names = get_function_parameter_names(refactor, function_declaration, bufnr)
            local argument_values = get_function_arguments(refactor, reference, bufnr)
            local constants = get_params_as_constants(refactor, parameter_names, argument_values)
            local region = utils.region_one_line_up_from_node(reference)
            for _, constant in ipairs(constants) do
                local insert_text = lsp_utils.insert_text(region, constant)
                table.insert(text_edits, insert_text)
            end
        end

        -- inlines function body into the new place
        for _, reference in ipairs(function_references) do
            local region = utils.region_one_line_up_from_node(reference)
            for _, edit in ipairs(inlined_sentences_edits(refactor, region, bufnr)) do
                table.insert(text_edits, edit)
            end
        end

        -- rewrites returned values into constants with its proper names
        local returned_values = get_function_returned_values(refactor, function_declaration, bufnr)
        local constants = get_params_as_constants(refactor, function_receivers_names, returned_values)
        for _, reference in ipairs(function_references) do
            local region = utils.region_one_line_up_from_node(reference)
            for _, constant in ipairs(constants) do
                local insert_text = lsp_utils.insert_text(region, constant)
                table.insert(text_edits, insert_text)
            end
        end

        -- deletes the original reference
        for _, reference in ipairs(function_references) do
            local region = Region:from_node(reference:parent():parent():parent(), bufnr)
            for _, edit in ipairs(delete_region_edit(region)) do
                table.insert(text_edits, edit)
            end
        end
    else
        if #function_references == 0 then
            error("Error: no function usages to inline")
            return false, refactor
        end

        -- rewrites each parameter with its value in the new place
        for _, reference in ipairs(function_references) do
            local parameter_names = get_function_parameter_names(refactor, function_declaration, bufnr)
            local argument_values = get_function_arguments(refactor, reference, bufnr)
            local constants = get_params_as_constants(refactor, parameter_names, argument_values)
            local region = utils.region_one_line_up_from_node(reference)
            for _, constant in ipairs(constants) do
                local insert_text = lsp_utils.insert_text(region, constant)
                table.insert(text_edits, insert_text)
            end
        end

        -- inlines function body into the new place
        for _, reference in ipairs(function_references) do
            local region = Region:from_node(reference:parent(), bufnr)
            for _, edit in ipairs(inlined_sentences_edits(refactor, region, bufnr)) do
                table.insert(text_edits, edit)
            end
        end

        -- deletes the original reference
        for _, reference in ipairs(function_references) do
            local region = Region:from_node(reference:parent(), bufnr)
            for _, edit in ipairs(delete_region_edit(region)) do
                table.insert(text_edits, edit)
            end
        end
    end

    -- deletes function declaration
    local function_declaration_region = Region:from_node(function_declaration, bufnr)
    table.insert(text_edits, lsp_utils.delete_text(function_declaration_region))

    refactor.text_edits = text_edits

    return true, refactor
end

---@param bufnr number
---@param opts table
function M.inline_func(bufnr, opts)
    get_inline_setup_pipeline(bufnr, opts)
        :add_task(
        --- @param refactor Refactor
            function(refactor)
                return inline_func_setup(refactor, bufnr)
            end
        )
        :after(post_refactor.post_refactor)
        :run(nil, vim.notify)
end

return M
