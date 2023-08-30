local Pipeline = require("refactoring.pipeline")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local post_refactor = require("refactoring.tasks.post_refactor")
local ts_locals = require("refactoring.ts-locals")
local Region = require("refactoring.region")
local lsp_utils = require("refactoring.lsp_utils")
local utils = require("refactoring.utils")
local indent = require("refactoring.indent")
local code = require("refactoring.code_generation")

local M = {}

---@param refactor Refactor
---@return TSNode? declarator
---@return TSNode? identifier
local function get_function_declaration(refactor)
    local current_node = vim.treesitter.get_node({ bufnr = refactor.bufnr })

    if current_node == nil then
        return nil, nil
    end

    local definition = ts_locals.find_definition(current_node, refactor.bufnr)
    local declarator_node =
        refactor.ts.get_container(definition, refactor.ts.function_scopes)

    if declarator_node and definition then
        return declarator_node, definition
    end
end

---@param refactor Refactor
---@param function_declaration TSNode
---@param identifier TSNode
---@return TSNode[]
local function get_references(refactor, function_declaration, identifier)
    ---@type TSNode[]
    local values = {}
    for _, value in
        ipairs(
            refactor.ts:loop_thru_nodes(
                function_declaration,
                refactor.ts.function_references
            )
        )
    do
        -- TODO: ugly ugly! -- need to filter out extra references to another functions
        if
            vim.treesitter.get_node_text(value, refactor.bufnr)
            == vim.treesitter.get_node_text(identifier, refactor.bufnr)
        then
            table.insert(values, value)
        end
    end
    return values
end

---@param refactor Refactor
---@param function_declaration TSNode
---@return string[]
local function get_function_returned_values(refactor, function_declaration)
    ---@type string[]
    local values = {}
    for _, value in
        ipairs(
            refactor.ts:loop_thru_nodes(
                function_declaration,
                refactor.ts.return_values
            )
        )
    do
        table.insert(
            values,
            vim.treesitter.get_node_text(value, refactor.bufnr)
        )
    end
    return values
end

---@param refactor Refactor
---@param function_declaration TSNode
---@return string[]
local function get_function_parameter_names(refactor, function_declaration)
    ---@type string[]
    local values = {}
    for _, value in
        ipairs(
            refactor.ts:loop_thru_nodes(
                function_declaration,
                refactor.ts.function_args
            )
        )
    do
        table.insert(
            values,
            vim.treesitter.get_node_text(value, refactor.bufnr)
        )
    end
    return values
end

---@param refactor Refactor
---@param declarator_node TSNode
---@return string[]
local function get_function_arguments(refactor, declarator_node)
    ---@type string[]
    local args = {}
    for _, value in
        ipairs(
            refactor.ts:loop_thru_nodes(
                declarator_node,
                refactor.ts.caller_args
            )
        )
    do
        table.insert(args, vim.treesitter.get_node_text(value, refactor.bufnr))
    end
    return args
end

---@param refactor Refactor
---@param function_declaration TSNode
---@return string[]
local function get_function_body_text(refactor, function_declaration)
    local function_body_text = {}

    local function_body = refactor.ts:get_function_body(function_declaration)

    for _, statement in ipairs(function_body) do
        local region = Region:from_node(statement)
        local region_with_indent = Region:from_values(
            refactor.bufnr,
            region.start_row,
            1,
            region.end_row,
            region.end_col
        )
        for _, line in ipairs(region_with_indent:get_text()) do
            if
                refactor.ts.is_return_statement
                and not refactor.ts.is_return_statement(line)
            then
                table.insert(function_body_text, line)
            end
        end
    end

    return function_body_text
end

---@param refactor Refactor
---@param indent_space string
---@param keys string[]
---@param values string[]
---@return string[]
local function get_params_as_constants(refactor, indent_space, keys, values)
    -- TODO: keys length and values should be the same
    ---@type string[]
    local constants = {}
    for idx, _ in ipairs(values) do
        -- TODO: refactor to a one line constant
        if idx == 1 then
            table.insert(
                constants,
                refactor.code.constant({
                    name = keys[idx],
                    value = values[idx],
                })
            )
        else
            table.insert(constants, indent_space .. refactor.code.constant({
                name = keys[idx],
                value = values[idx],
            }))
        end
    end
    return constants
end

---@param refactor Refactor
---@return boolean
---@return Refactor|string
local function inline_func_setup(refactor)
    -- TODO: need to get function declaration no matter if we are at the definition or at any reference
    local function_declaration, identifier = get_function_declaration(refactor)

    if function_declaration == nil or identifier == nil then
        return false, "No function declaration found"
    end

    local function_references =
        get_references(refactor, function_declaration:parent(), identifier)

    if #function_references == 0 then
        return false, "Error: no function usages to inline"
    end

    local text_edits = {}
    local function_body_text =
        get_function_body_text(refactor, function_declaration)
    local returned_values =
        get_function_returned_values(refactor, function_declaration)
    local parameters =
        get_function_parameter_names(refactor, function_declaration)

    local refactor_is_possible = false

    -- TODO (TheLeoP): check if indenting is suported in all of 115
    indent.lines_remove_indent(
        function_body_text,
        1,
        #function_body_text,
        indent.line_indent_amount(function_body_text[1] or "", refactor.bufnr),
        refactor.bufnr
    )

    for _, reference in ipairs(function_references) do
        -- TODO (TheLeoP): check if this can be done using `indent.buf_indent_amount`
        --
        -- Copy indentation of the line where the function is called
        local reference_region = Region:from_node(reference)
        local region_with_indent = Region:from_values(
            refactor.bufnr,
            reference_region.start_row,
            1,
            reference_region.end_row,
            reference_region.end_col
        )
        local indent_amount = indent.line_indent_amount(
            region_with_indent:get_text()[1],
            refactor.bufnr
        )
        local indent_space = indent.indent(indent_amount, refactor.bufnr)

        -- inlines function body into the new place (without return statements)
        if
            #parameters == 0
            and #returned_values == 0
            and #function_body_text > 0
        then
            refactor_is_possible = true
            for _, sentence in ipairs(function_body_text) do
                table.insert(
                    text_edits,
                    lsp_utils.insert_new_line_text(
                        Region:from_node(reference:parent(), refactor.bufnr),
                        indent_space .. sentence,
                        -- TODO (TheLeoP): which opts should be used here?
                        {}
                    )
                )
            end
        end

        -- replaces the function call with the returned value
        -- TODO: this could be merged into next one
        if
            #parameters == 0
            and #returned_values == 1
            and #function_body_text == 0
        then
            refactor_is_possible = true
            for _, sentence in ipairs(returned_values) do
                table.insert(
                    text_edits,
                    lsp_utils.insert_text(
                        Region:from_node(reference:parent(), refactor.bufnr),
                        sentence
                    )
                )
            end
        end

        -- replaces the function call with the returned value and inlines the function body
        if
            #parameters == 0
            and #returned_values == 1
            and #function_body_text > 0
        then
            refactor_is_possible = true
            for _, sentence in ipairs(function_body_text) do
                table.insert(
                    text_edits,
                    lsp_utils.insert_new_line_text(
                        utils.region_one_line_up_from_node(reference),
                        indent_space .. sentence,
                        {}
                    )
                )
            end
            for _, sentence in ipairs(returned_values) do
                table.insert(
                    text_edits,
                    lsp_utils.insert_text(
                        Region:from_node(reference:parent(), refactor.bufnr),
                        sentence
                    )
                )
            end
        end

        -- replaces the function call with the returned values (multiple)
        -- TODO: this could be merged into the next one
        if
            #parameters == 0
            and #returned_values > 1
            and #function_body_text == 0
        then
            refactor_is_possible = true
            for idx, sentence in ipairs(returned_values) do
                local comma = ""
                if idx ~= #returned_values then
                    comma = ", "
                end
                table.insert(
                    text_edits,
                    lsp_utils.insert_text(
                        Region:from_node(reference:parent(), refactor.bufnr),
                        sentence .. comma
                    )
                )
            end
        end

        -- replaces the function call with the returned values (multiple) and alse function body (multiple lines)
        if
            #parameters == 0
            and #returned_values > 1
            and #function_body_text > 1
        then
            refactor_is_possible = true
            for _, sentence in ipairs(function_body_text) do
                table.insert(
                    text_edits,
                    lsp_utils.insert_new_line_text(
                        utils.region_one_line_up_from_node(reference),
                        indent_space .. sentence,
                        -- TODO: this could be merged into the next one
                        {}
                    )
                )
            end
            for idx, sentence in ipairs(returned_values) do
                local comma = ""
                if idx ~= #returned_values then
                    comma = ", "
                end
                table.insert(
                    text_edits,
                    lsp_utils.insert_text(
                        Region:from_node(reference:parent(), refactor.bufnr),
                        sentence .. comma
                    )
                )
            end
        end

        -- replaces the function call with the body and creates a constant to store the function arguments
        if
            #parameters > 0
            and #returned_values == 0
            and #function_body_text > 0
        then
            refactor_is_possible = true
            local arguments_list =
                get_function_arguments(refactor, reference:parent())
            local constants = get_params_as_constants(
                refactor,
                indent_space,
                parameters,
                arguments_list
            )
            for _, constant in ipairs(constants) do
                local insert_text = lsp_utils.insert_text(
                    Region:from_node(reference:parent(), refactor.bufnr),
                    constant
                )
                table.insert(text_edits, insert_text)
            end
            for _, sentence in ipairs(function_body_text) do
                local new_line = ""
                if #function_body_text > 1 then
                    new_line = code.new_line()
                end
                table.insert(
                    text_edits,
                    lsp_utils.insert_text(
                        Region:from_node(reference:parent(), refactor.bufnr),
                        indent_space .. sentence .. new_line
                    )
                )
            end
        end

        -- replaces the function call with all params and create constants for the given param
        if
            #parameters > 0
            and #returned_values > 0
            and #function_body_text == 0
        then
            refactor_is_possible = true
            local arguments_list =
                get_function_arguments(refactor, reference:parent())
            local constants = get_params_as_constants(
                refactor,
                indent_space,
                parameters,
                arguments_list
            )
            for _, constant in ipairs(constants) do
                table.insert(
                    text_edits,
                    lsp_utils.insert_text(
                        utils.region_one_line_up_from_node(reference),
                        indent_space .. constant
                    )
                )
            end
            for idx, sentence in ipairs(returned_values) do
                local comma = ""
                if idx ~= #returned_values then
                    comma = ", "
                end
                table.insert(
                    text_edits,
                    lsp_utils.insert_text(
                        Region:from_node(reference:parent(), refactor.bufnr),
                        sentence .. comma
                    )
                )
            end
        end

        if
            #parameters > 0
            and #returned_values > 0
            and #function_body_text > 0
        then
            refactor_is_possible = true
            local new_line = code.new_line()

            local arguments_list =
                get_function_arguments(refactor, reference:parent())
            local constants = get_params_as_constants(
                refactor,
                indent_space,
                parameters,
                arguments_list
            )
            for _, constant in ipairs(constants) do
                table.insert(
                    text_edits,
                    lsp_utils.insert_text(
                        utils.region_one_line_up_from_node(reference),
                        indent_space .. constant
                    )
                )
            end
            for _, sentence in ipairs(function_body_text) do
                table.insert(
                    text_edits,
                    lsp_utils.insert_text(
                        utils.region_one_line_up_from_node(reference),
                        indent_space .. sentence .. new_line
                    )
                )
            end
            for idx, sentence in ipairs(returned_values) do
                local comma = ""
                if idx ~= #returned_values then
                    comma = ", "
                end
                table.insert(
                    text_edits,
                    lsp_utils.insert_text(
                        Region:from_node(reference:parent(), refactor.bufnr),
                        sentence .. comma
                    )
                )
            end
        end

        if refactor_is_possible then
            -- Delete original reference
            local delete_text = lsp_utils.delete_text(
                Region:from_node(reference:parent(), refactor.bufnr)
            )
            table.insert(text_edits, delete_text)
        end
    end

    if refactor_is_possible then
        -- deletes function declaration
        table.insert(
            text_edits,
            lsp_utils.delete_text(
                Region:from_node(function_declaration, refactor.bufnr)
            )
        )
    else
        vim.print({
            returned_values = returned_values,
            function_body_text = function_body_text,
            parameters_names = parameters,
        })
        return false, "inline function is not possible"
    end

    refactor.text_edits = text_edits
    return true, refactor
end

---@param bufnr integer
---@param opts Config
function M.inline_func(bufnr, opts)
    Pipeline:from_task(refactor_setup(bufnr, opts))
        :add_task(inline_func_setup)
        :after(post_refactor.post_refactor)
        :run(nil, vim.notify)
end

return M
