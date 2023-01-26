local Region = require("refactoring.region")
local utils = require("refactoring.utils")
local get_input = require("refactoring.get_input")
local Query = require("refactoring.query")
local Pipeline = require("refactoring.pipeline")
local selection_setup = require("refactoring.tasks.selection_setup")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local post_refactor = require("refactoring.tasks.post_refactor")
local ensure_code_gen = require("refactoring.tasks.ensure_code_gen")
local indent = require("refactoring.indent")

local M = {}

---@param refactor Refactor
---@param region RefactorRegion
---@return string
local function get_func_call_prefix(refactor, region)
    local indent_amount = indent.buf_indent_amount(
        region:get_start_point(),
        refactor,
        false,
        refactor.bufnr
    )
    return indent.indent(indent_amount, refactor.bufnr)
end

---@param extract_node_text string
---@param refactor Refactor
---@param var_name string
---@param region RefactorRegion
---@return string
local function get_new_var_text(extract_node_text, refactor, var_name, region)
    local statement =
        refactor.config:get_extract_var_statement(refactor.filetype)
    local base_text = refactor.code.constant({
        name = var_name,
        value = extract_node_text,
        statement = statement,
    })

    if
        refactor.ts:is_indent_scope(refactor.scope)
        and refactor.ts:allows_indenting_task()
    then
        local indent_whitespace = get_func_call_prefix(refactor, region)
        local indented_text = {}
        indented_text[1] = indent_whitespace
        indented_text[2] = base_text
        return table.concat(indented_text, "")
    end

    return base_text
end

---@param refactor Refactor
local function extract_var_setup(refactor)
    local extract_node = refactor.region_node

    local extract_node_text =
        table.concat(utils.get_node_text(extract_node), "")

    local sexpr = extract_node:sexpr()
    local occurrences =
        Query.find_occurrences(refactor.scope, sexpr, refactor.bufnr)

    local actual_occurrences = {}
    local texts = {}

    for _, occurrence in pairs(occurrences) do
        local text = table.concat(utils.get_node_text(occurrence), "")
        if text == extract_node_text then
            table.insert(actual_occurrences, occurrence)
            table.insert(texts, text)
        end
    end
    utils.sort_in_appearance_order(actual_occurrences)

    local var_name = get_input("119: What is the var name > ")
    assert(var_name ~= "", "Error: Must provide new var name")

    refactor.text_edits = {}
    for _, occurrence in pairs(actual_occurrences) do
        local region = Region:from_node(occurrence, refactor.bufnr)
        table.insert(refactor.text_edits, {
            add_newline = false,
            region = region,
            text = var_name,
        })
    end

    local block_scope =
        refactor.ts.get_container(refactor.region_node, refactor.ts.block_scope)

    -- TODO: Add test for block_scope being nil
    if block_scope == nil then
        error("block_scope is nil! Something went wrong")
    end

    local unfiltered_statements = refactor.ts:get_statements(block_scope)

    -- TODO: Add test for unfiltered_statements being nil
    if #unfiltered_statements < 1 then
        error("unfiltered_statements is nil! Something went wrong")
    end

    local statements = vim.tbl_filter(function(node)
        return node:parent():id() == block_scope:id()
    end, unfiltered_statements)
    utils.sort_in_appearance_order(statements)

    -- TODO: Add test for statements being nil
    if #statements < 1 then
        error("statements is nil! Something went wrong")
    end

    local contained = nil
    local top_occurrence = actual_occurrences[1]
    for _, statement in pairs(statements) do
        if utils.node_contains(statement, top_occurrence) then
            contained = statement
        end
    end

    if not contained then
        error(
            "Extract var unable to determine its containing statement within the block scope, please post issue with exact highlight + code!  Thanks"
        )
    end

    local region = utils.region_one_line_up_from_node(contained)
    table.insert(refactor.text_edits, {
        add_newline = false,
        region = region,
        text = get_new_var_text(extract_node_text, refactor, var_name, region),
    })
end

---@param refactor Refactor
local function ensure_code_gen_119(refactor)
    local list = { "constant" }

    if refactor.ts:allows_indenting_task() then
        table.insert(list, "indent")
    end
    return ensure_code_gen(refactor, list)
end

function M.extract_var(bufnr, config)
    Pipeline:from_task(refactor_setup(bufnr, config))
        :add_task(
            ---@param refactor Refactor
            function(refactor)
                return ensure_code_gen_119(refactor)
            end
        )
        :add_task(selection_setup)
        :add_task(
            ---@param refactor Refactor
            function(refactor)
                extract_var_setup(refactor)
                return true, refactor
            end
        )
        :after(post_refactor.post_refactor)
        :run()
end

return M
