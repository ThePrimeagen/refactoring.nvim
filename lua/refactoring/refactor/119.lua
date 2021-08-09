local Region = require("refactoring.region")
local utils = require("refactoring.utils")
local get_input = require("refactoring.get_input")
local Query = require("refactoring.query")
local Pipeline = require("refactoring.pipeline")
local selection_setup = require("refactoring.pipeline.selection_setup")
local refactor_setup = require("refactoring.pipeline.refactor_setup")
local post_refactor = require("refactoring.pipeline.post_refactor")
local Config = require("refactoring.config")

local M = {}

function M.extract_var(bufnr)
    Pipeline
        :from_task(refactor_setup(bufnr, Config.get_config()))
        :add_task(selection_setup)
        :add_task(function(refactor)
            local extract_node = refactor.root:named_descendant_for_range(
                refactor.region:to_ts()
            )
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

            local var_name = get_input("119: What is the var name > ")
            refactor.text_edits = {}
            for _, occurrence in pairs(actual_occurrences) do
                local region = Region:from_node(occurrence, refactor.bufnr)
                table.insert(refactor.text_edits, {
                    add_newline = false,
                    region = region,
                    text = var_name,
                })
            end

            --[[
            local unfiltered_statements = refactor.query:pluck_by_capture(
                refactor.scope,
                Query.query_type.Statement
            )

            local statements = vim.tbl_filter(function(node)
                return node:parent():id() == refactor.scope:id()
            end, unfiltered_statements)

            for _, statement in pairs(statements) do
                print("Statement", utils.get_node_text(statement))
            end
            --]]

            return true, refactor
        end)
        :after(post_refactor)
        :run()
end

return M
