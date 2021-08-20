--[[
local Region = require("refactoring.region")
local get_input = require("refactoring.get_input")
local Query = require("refactoring.query")
]]
local Region = require("refactoring.region")
local utils = require("refactoring.utils")
local lsp_utils = require("refactoring.lsp_utils")
local ensure_lsp = require("refactoring.tasks.ensure_lsp")
local Pipeline = require("refactoring.pipeline")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local post_refactor = require("refactoring.tasks.post_refactor")
local Config = require("refactoring.config")
local Query = require("refactoring.query")

local M = {}

function M.inline_var(bufnr)
    Pipeline
        :from_task(refactor_setup(bufnr, Config.get_config())) -- 1. ensure LSP is available
        :add_task(ensure_lsp)
        :add_task(function(refactor)
            -- 2. Find definition and references
            local beans = 69
            local foo = 5 * beans
            local definition = lsp_utils.get_definition_under_cursor(
                refactor.bufnr
            )
            local def_region = Region:from_lsp_range(
                definition.targetRange or definition.range
            )
            local references = lsp_utils.get_references_under_cursor(
                refactor.bufnr,
                def_region
            )

            -- 3. Ensure every reference and definition come from the same bufnr.
            -- Inlining probably should even be bound to scope.
            -- TODO: targetUri seems to happen on lua file and uri happens on typescript...
            if
                refactor.bufnr
                ~= lsp_utils.lsp_uri_to_bufnr(
                    definition.targetUri or definition.uri
                )
            then
                return false,
                    "definition of var does not exist within current file."
            end

            for _, ref in pairs(references) do
                if refactor.bufnr ~= lsp_utils.lsp_uri_to_bufnr(ref.uri) then
                    return false,
                        "reference to variable about to be inlined exist outside of current file."
                end
            end

            -- 4. Get value of definition
            -- TODO: Same above note.  range and targetRange... why do they differ?

            local declarator_node = refactor.query:get_scope_over_region(
                def_region,
                Query.query_type.Declarator
            )

            local value_node = refactor.query:pluck_by_capture(
                declarator_node,
                Query.query_type.LocalVarValue
            )[1]
            if not value_node then
                error("Unable to find the value node of the local declarator")
            end

            -- TODO: How do we deal with a multiline function in python with
            -- inlining. Lose newlines... this is dangerous
            local value_text = table.concat(utils.get_node_text(value_node), "")

            -- 5. Delete declaration
            local text_edits = {}
            table.insert(
                text_edits,
                lsp_utils.delete_text(Region:from_node(declarator_node))
            )

            -- 6. Replace references
            for _, ref in pairs(references) do
                local insert_text, delete_text = lsp_utils.replace_text(
                    Region:from_lsp_range(ref.range),
                    value_text
                )

                table.insert(text_edits, insert_text)
                table.insert(text_edits, delete_text)
            end

            refactor.text_edits = text_edits
            print(vim.inspect(text_edits))
            return true, refactor, foo
        end)
        :after(post_refactor)
        :run()
end

return M
