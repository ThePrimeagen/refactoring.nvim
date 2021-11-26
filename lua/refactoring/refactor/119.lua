local Region = require("refactoring.region")
local utils = require("refactoring.utils")
local get_input = require("refactoring.get_input")
local Query = require("refactoring.query")
local Pipeline = require("refactoring.pipeline")
local selection_setup = require("refactoring.tasks.selection_setup")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local post_refactor = require("refactoring.tasks.post_refactor")

local M = {}

function M.extract_var(bufnr, config)
    Pipeline
        :from_task(refactor_setup(bufnr, config))
        :add_task(selection_setup)
        :add_task(function(refactor)
            local extract_node = refactor.region_node

            local extract_node_text = table.concat(
                utils.get_node_text(extract_node),
                ""
            )

            local sexpr = extract_node:sexpr()
            local occurrences = Query.find_occurrences(
                refactor.scope,
                sexpr,
                refactor.bufnr
            )

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

            local block_scope = refactor.ts.get_container(
                refactor.region_node,
                refactor.ts.block_scope
            )

            -- TODO: Create inline node for TS stuff.
            local unfiltered_statements = refactor.query:pluck_by_capture(
                block_scope,
                Query.query_type.Statement
            )

            local statements = vim.tbl_filter(function(node)
                return node:parent():id() == block_scope:id()
            end, unfiltered_statements)
            utils.sort_in_appearance_order(statements)

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
            local code = refactor.code.constant({
                name = var_name,
                value = extract_node_text,
            })

            table.insert(refactor.text_edits, {
                add_newline = false,
                region = utils.region_one_line_up_from_node(contained),
                text = code,
            })

            return true, refactor
        end)
        :after(post_refactor)
        :run()
end

return M
