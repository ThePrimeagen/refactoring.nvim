local LspDefinition = require("refactoring.lsp")
local Region = require("refactoring.region")
local lsp_utils = require("refactoring.lsp_utils")
local ensure_lsp = require("refactoring.tasks.ensure_lsp")
local Pipeline = require("refactoring.pipeline")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local post_refactor = require("refactoring.tasks.post_refactor")
local Config = require("refactoring.config")

local M = {}

function M.inline_var(bufnr)
    Pipeline
        :from_task(refactor_setup(bufnr, Config.get_config())) -- 1. ensure LSP is available
        :add_task(ensure_lsp)
        :add_task(function(refactor)
            local lsp_definition = LspDefinition:from_cursor(
                bufnr,
                refactor.query
            )

            local references = lsp_utils.get_references_under_cursor(
                refactor.bufnr,
                lsp_definition.definition_region
            )

            if
                refactor.bufnr
                ~= lsp_utils.lsp_uri_to_bufnr(
                    lsp_definition.definition.targetUri
                        or lsp_definition.definition.uri
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

            local text_edits = {}
            table.insert(
                text_edits,
                lsp_utils.delete_text(
                    Region:from_node(lsp_definition.declarator_node)
                )
            )

            local value_text = lsp_definition:get_value_text()
            for _, ref in pairs(references) do
                local insert_text, delete_text = lsp_utils.replace_text(
                    Region:from_lsp_range(ref.range),
                    value_text
                )

                table.insert(text_edits, insert_text)
                table.insert(text_edits, delete_text)
            end

            refactor.text_edits = text_edits
            return true, refactor
        end)
        :after(post_refactor)
        :run()
end

return M
