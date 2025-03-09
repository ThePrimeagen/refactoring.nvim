local Region = require("refactoring.region")
local utils = require("refactoring.utils")
local ui = require("refactoring.ui")
local Query = require("refactoring.query")
local Pipeline = require("refactoring.pipeline")
local tasks = require("refactoring.tasks")
local indent = require("refactoring.indent")
local text_edits_utils = require("refactoring.text_edits_utils")
local notify = require("refactoring.notify")

local api = vim.api

local M = {}

---@param extract_node_text string
---@param refactor Refactor
---@param var_name string
---@param new_var_pos RefactorPoint
---@return string
local function get_new_var_text(
    extract_node_text,
    refactor,
    var_name,
    new_var_pos
)
    local statement =
        refactor.config:get_extract_var_statement(refactor.filetype)
    local base_text = refactor.code.constant({
        name = var_name,
        value = extract_node_text,
        statement = statement,
    })

    local current_statement_line = api.nvim_buf_get_lines(
        refactor.bufnr,
        new_var_pos.row - 1,
        new_var_pos.row,
        true
    )[1]
    -- it's assumed that the extracted var has the same indentation as the
    -- statement under cursor where the refactor was started
    local indent_amount =
        indent.line_indent_amount(current_statement_line, refactor.bufnr)
    local indentation = indent.indent(indent_amount, refactor.bufnr)

    return table.concat({ indentation, base_text })
end

---@param var_name string
---@param refactor Refactor
---@return string
local function get_var_name(var_name, refactor)
    if refactor.ts.require_special_var_format then
        return refactor.code.special_var(
            var_name,
            { region_node_type = refactor.region_node:type() }
        )
    else
        return var_name
    end
end

---@param refactor Refactor
---@return boolean, Refactor|string
local function extract_var_setup(refactor)
    local extract_node = refactor.region_node

    if extract_node == nil then
        return false, "Region node is nil. Something went wrong"
    end

    local extract_node_text =
        vim.treesitter.get_node_text(extract_node, refactor.bufnr)
    local extract_node_text_without_whitespace =
        table.concat(utils.get_node_text(extract_node), "")

    ---@type string
    local sexpr = extract_node:sexpr()
    local occurrences =
        Query.find_occurrences(refactor.scope, sexpr, refactor.bufnr)

    --- @type TSNode[]
    local actual_occurrences = {}
    ---@type string[]
    local texts = {}

    for _, occurrence in pairs(occurrences) do
        local text = vim.treesitter.get_node_text(occurrence, refactor.bufnr)
        local text_without_whitespace =
            table.concat(utils.get_node_text(occurrence), "")
        if text_without_whitespace == extract_node_text_without_whitespace then
            table.insert(actual_occurrences, occurrence)
            table.insert(texts, text)
        end
    end
    utils.sort_in_appearance_order(actual_occurrences)

    local var_name = ui.input("119: What is the var name > ")
    if not var_name or var_name == "" then
        return false, "Error: Must provide new var name"
    end

    refactor.text_edits = {}
    for _, occurrence in pairs(actual_occurrences) do
        table.insert(
            refactor.text_edits,
            text_edits_utils.replace_text(
                Region:from_node(occurrence, refactor.bufnr),
                get_var_name(var_name, refactor)
            )
        )
    end
    refactor.success_message = ("Extracted %s variable occurrences"):format(
        #actual_occurrences
    )

    --- @type TSNode[]
    local block_scopes = {}
    --- @type table<string, true>
    local already_seen = {}
    for _, occurrence in pairs(actual_occurrences) do
        local block_scope =
            refactor.ts.get_container(occurrence, refactor.ts.block_scope)
        if block_scope == nil then
            return false, "block_scope is nil! Something went wrong"
        end
        if already_seen[block_scope:id()] == nil then
            already_seen[block_scope:id()] = true
            table.insert(block_scopes, block_scope)
        end
    end
    utils.sort_in_appearance_order(block_scopes)

    if #block_scopes < 1 then
        return false, "block_scope is nil! Something went wrong"
    end

    local ok, unfiltered_statements =
        pcall(refactor.ts.get_statements, refactor.ts, block_scopes[1])
    if not ok then
        return ok, unfiltered_statements
    end

    if #unfiltered_statements < 1 then
        return false, "unfiltered_statements is nil! Something went wrong"
    end

    ---@type TSNode[]
    local statements = vim.iter(unfiltered_statements)
        :filter(
            ---@param node TSNode
            ---@return TSNode[]
            function(node)
                for _, scope in pairs(block_scopes) do
                    if node:parent():id() == scope:id() then
                        return true
                    end
                end
                return false
            end
        )
        :totable()
    utils.sort_in_appearance_order(statements)

    if #statements < 1 then
        return false, "statements is nil! Something went wrong"
    end

    ---@type TSNode|nil
    local contained = nil
    local top_occurrence = actual_occurrences[1]
    for _, statement in ipairs(statements) do
        if utils.node_contains(statement, top_occurrence) then
            contained = statement
        end
    end

    if not contained then
        return false,
            "Extract var unable to determine its containing statement within the block scope, please post issue with exact highlight + code!  Thanks"
    end

    local region = utils.region_one_line_up_from_node(contained)
    local ok2, new_var_text = pcall(
        get_new_var_text,
        extract_node_text,
        refactor,
        var_name,
        region:get_start_point()
    )
    if not ok2 then
        return ok2, new_var_text
    end
    table.insert(
        refactor.text_edits,
        text_edits_utils.insert_text(region, new_var_text)
    )
    return true, refactor
end

---@param refactor Refactor
local function ensure_code_gen_119(refactor)
    local list = { "constant" }

    return tasks.ensure_code_gen(refactor, list)
end

---@param bufnr integer
---@param region_type 'v' | 'V' | ''
---@param config Config
function M.extract_var(bufnr, region_type, config)
    local seed = tasks.refactor_seed(bufnr, region_type, config)
    Pipeline:from_task(ensure_code_gen_119)
        :add_task(tasks.operator_setup)
        :add_task(extract_var_setup)
        :after(tasks.post_refactor)
        :run(nil, notify.error, seed)
end

return M
