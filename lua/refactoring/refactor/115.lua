local Pipeline = require("refactoring.pipeline")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local post_refactor = require("refactoring.tasks.post_refactor")
local ts = require("refactoring.ts")
local Region = require("refactoring.region")
local lsp_utils = require("refactoring.lsp_utils")
local utils = require("refactoring.utils")
local indent = require("refactoring.indent")
local code = require("refactoring.code_generation")

local M = {}

local function get_inline_setup_pipeline(bufnr, opts)
    return Pipeline:from_task(refactor_setup(bufnr, opts))
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

local function get_references(refactor, function_declaration, identifier, bufnr)
    local values = {}
    for _, value in ipairs(refactor.ts:loop_thru_nodes(function_declaration, refactor.ts.function_references)) do
        -- TODO: ugly ugly! -- need to filter out extra references to another functions
        if vim.treesitter.get_node_text(value, bufnr) == vim.treesitter.get_node_text(identifier, bufnr) then
            table.insert(values, value)
        end
    end
    return values
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
    for _, value in ipairs(refactor.ts:loop_thru_nodes(function_declaration, refactor.ts.function_args)) do
        table.insert(values, vim.treesitter.get_node_text(value, bufnr))
    end
    return values
end

local function get_function_arguments(refactor, declarator_node, bufnr)
    local args = {}
    for _, value in ipairs(refactor.ts:loop_thru_nodes(declarator_node, refactor.ts.caller_args)) do
        table.insert(args, vim.treesitter.get_node_text(value, bufnr))
    end
    return args
end

local function get_function_body_text(refactor, function_declaration, bufnr)
    local block_first_child = refactor.ts:get_function_body(function_declaration)[1]
    local block_last_child = block_first_child -- starting off here, we're going to find it manually

    -- we have to find the last direct sibling manually because raw queries
    -- pick up nested children nodes as well
    while block_last_child:next_named_sibling() do
        block_last_child = block_last_child:next_named_sibling()
    end

    local first_line_region = Region:from_node(block_first_child)
    local last_line_region = Region:from_node(block_last_child)

    -- update the region and its node with the block scope found
    local region = Region:from_values(
        bufnr,
        first_line_region.start_row,
        -- The Tresitter delimited region never includes the blank spaces
        -- before the first line which causes problems with indentation.
        1,
        last_line_region.end_row,
        last_line_region.end_col
    )


    local function_body = {}
    for _, sentence in ipairs(region:get_text()) do
        local trimmed = utils.trim(sentence) --[[@as string]]
        if trimmed:find("return", 1, true) ~= 1 then
            table.insert(function_body, sentence)
        end
    end
    return function_body
end

local function get_function_body(refactor, function_declaration, bufnr)
    local function_body = {}
    local sentences = refactor.ts:get_function_body(function_declaration)
    -- TODO: try to fix indent in one single place
    for _, sentence in ipairs(sentences) do
        if sentence:type() ~= "return_statement" then
            table.insert(function_body, vim.treesitter.get_node_text(sentence, bufnr))
        end
    end
    return function_body
end

local function get_indent_spaces(refactor, node, bufnr)
    local indent_amount = indent.buf_indent_amount(
        Region:from_node(node, bufnr):get_start_point(),
        refactor,
        false,
        refactor.bufnr
    )
    return indent.indent(indent_amount, refactor.bufnr)
end

local function get_params_as_constants(refactor, indent_space, keys, values)
    -- TODO: keys length and values should be the same
    local constants = {}
    for idx, _ in ipairs(values) do
        -- TODO: refactor to a one line constant
        if idx == 1 then
            table.insert(constants, refactor.code.constant({
                name = keys[idx],
                value = values[idx],
            }))
        else
            table.insert(constants, indent_space .. refactor.code.constant({
                name = keys[idx],
                value = values[idx],
            }))
        end
    end
    return constants
end

local function inline_func_setup(refactor, bufnr)
    -- TODO: need to get function declaration no matter if we are at the definition or at any reference
    local function_declaration, identifier = get_function_declaration(refactor, bufnr)
    local function_references              = get_references(refactor, function_declaration:parent(), identifier, bufnr)

    if #function_references == 0 then
        error("Error: no function usages to inline")
        return false, refactor
    end

    local text_edits = {}
    local function_declaration_body = get_function_body(refactor, function_declaration, bufnr)
    local function_declaration_text = get_function_body_text(refactor, function_declaration, bufnr)
    local returned_values = get_function_returned_values(refactor, function_declaration, bufnr)
    local parameters_list = get_function_parameter_names(refactor, function_declaration, bufnr)
    local has_params = #parameters_list > 0

    local refactor_is_possible = false

    for _, reference in ipairs(function_references) do
        local indent_space = get_indent_spaces(refactor, reference:parent(), bufnr)

        -- inlines function body into the new place (without return statements)
        if #parameters_list == 0 and #returned_values == 0 and #function_declaration_body > 0 then
            refactor_is_possible = true
            for _, sentence in ipairs(function_declaration_body) do
                table.insert(text_edits, lsp_utils.insert_new_line_text(
                    Region:from_node(reference:parent(), bufnr),
                    indent_space .. sentence,
                    {}
                ))
            end
        end

        -- replaces the function call with the returned value
        -- TODO: this could be merged into next one
        if #parameters_list == 0 and #returned_values == 1 and #function_declaration_body == 0 then
            refactor_is_possible = true
            for _, sentence in ipairs(returned_values) do
                table.insert(text_edits, lsp_utils.insert_text(Region:from_node(reference:parent(), bufnr), sentence))
            end
        end

        -- replaces the function call with the returned value and inlines the function body
        if #parameters_list == 0 and #returned_values == 1 and #function_declaration_body > 0 then
            refactor_is_possible = true
            for _, sentence in ipairs(function_declaration_body) do
                table.insert(text_edits, lsp_utils.insert_new_line_text(
                    utils.region_one_line_up_from_node(reference),
                    indent_space .. sentence,
                    {}
                ))
            end
            for _, sentence in ipairs(returned_values) do
                table.insert(text_edits, lsp_utils.insert_text(Region:from_node(reference:parent(), bufnr), sentence))
            end
        end

        -- replaces the function call with the returned values (multiple)
        -- TODO: this could be merged into the next one
        if #parameters_list == 0 and #returned_values > 1 and #function_declaration_body == 0 then
            refactor_is_possible = true
            for idx, sentence in ipairs(returned_values) do
                local comma = ""
                if idx ~= #returned_values then
                    comma = ", "
                end
                table.insert(text_edits,
                    lsp_utils.insert_text(Region:from_node(reference:parent(), bufnr), sentence .. comma))
            end
        end

        -- replaces the function call with the returned values (multiple) and alse function body (multiple lines)
        if #parameters_list == 0 and #returned_values > 1 and #function_declaration_body > 1 then
            refactor_is_possible = true
            for _, sentence in ipairs(function_declaration_body) do
                table.insert(text_edits, lsp_utils.insert_new_line_text(
                    utils.region_one_line_up_from_node(reference),
                    indent_space .. sentence,
                    {}
                ))
            end
            for idx, sentence in ipairs(returned_values) do
                local comma = ""
                if idx ~= #returned_values then
                    comma = ", "
                end
                table.insert(text_edits,
                    lsp_utils.insert_text(Region:from_node(reference:parent(), bufnr), sentence .. comma))
            end
        end

        -- replaces the function call with the body and creates a constant to store the function arguments
        if #parameters_list > 0 and #returned_values == 0 and #function_declaration_body > 0 then
            refactor_is_possible = true
            local arguments_list = get_function_arguments(refactor, reference:parent(), bufnr)
            local constants = get_params_as_constants(refactor, indent_space, parameters_list, arguments_list)
            for _, constant in ipairs(constants) do
                local insert_text = lsp_utils.insert_text(Region:from_node(reference:parent(), bufnr), constant)
                table.insert(text_edits, insert_text)
            end
            for _, sentence in ipairs(function_declaration_body) do
                local new_line = ""
                if #function_declaration_body > 1 then
                    new_line = code.new_line()
                end
                table.insert(text_edits, lsp_utils.insert_text(
                    Region:from_node(reference:parent(), bufnr),
                    indent_space .. sentence .. new_line
                ))
            end
        end

        -- replaces the function call with all params and create constants for the given param
        if #parameters_list > 0 and #returned_values > 0 and #function_declaration_body == 0 then
            refactor_is_possible = true
            local arguments_list = get_function_arguments(refactor, reference:parent(), bufnr)
            local constants = get_params_as_constants(refactor, indent_space, parameters_list, arguments_list)
            for _, constant in ipairs(constants) do
                table.insert(text_edits,
                    lsp_utils.insert_text(utils.region_one_line_up_from_node(reference), indent_space .. constant))
            end
            for idx, sentence in ipairs(returned_values) do
                local comma = ""
                if idx ~= #returned_values then
                    comma = ", "
                end
                table.insert(text_edits,
                    lsp_utils.insert_text(Region:from_node(reference:parent(), bufnr), sentence .. comma))
            end
        end

        if #parameters_list > 0 and #returned_values > 0 and (#function_declaration_body > 0 or #function_declaration_text > 0) then
            refactor_is_possible = true
            local new_line = code.new_line()
            -- TODO: a really tricy hack because function_declaration_body contains duplicated nodes that we don't want here
            -- TODO: need to try to reproduce this hack in the other implementations, nested of nested and comments inside of nested
            -- TODO: this code is not indented for now
            local function_body = function_declaration_body
            if #function_declaration_body ~= #function_declaration_text then
                function_body = function_declaration_text
            end
            -- end hack

            local arguments_list = get_function_arguments(refactor, reference:parent(), bufnr)
            local constants = get_params_as_constants(refactor, indent_space, parameters_list, arguments_list)
            for _, constant in ipairs(constants) do
                table.insert(text_edits,
                    lsp_utils.insert_text(utils.region_one_line_up_from_node(reference), indent_space .. constant))
            end
            for _, sentence in ipairs(function_body) do
                table.insert(text_edits, lsp_utils.insert_text(
                    utils.region_one_line_up_from_node(reference),
                    indent_space .. sentence .. new_line
                ))
            end
            for idx, sentence in ipairs(returned_values) do
                local comma = ""
                if idx ~= #returned_values then
                    comma = ", "
                end
                table.insert(text_edits,
                    lsp_utils.insert_text(Region:from_node(reference:parent(), bufnr), sentence .. comma))
            end
        end

        if refactor_is_possible then
            -- Delete original reference
            local delete_text = lsp_utils.delete_text(Region:from_node(reference:parent(), bufnr))
            table.insert(text_edits, delete_text)
        end
    end

    if refactor_is_possible then
        -- deletes function declaration
        table.insert(text_edits, lsp_utils.delete_text(Region:from_node(function_declaration, bufnr)))
    else
        print("inline function is not possible")
        print("rtr", #returned_values)
        print("bdy", #function_declaration_body)
        print("prm", #parameters_list)
        print("has", has_params)
        return false, "inline function is not possible"
    end

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
