-- Some other suggestions
-- You should remove lsp_utils and change it to: text_edits.*
--  this will make it much less confusing. It's not really about LSP,
--  it's just about using one of the data structures.
local Pipeline = require("refactoring.pipeline")
local Region = require("refactoring.region")
local post_refactor = require("refactoring.tasks.post_refactor")
local refactor_setup = require("refactoring.tasks.refactor_setup")

local lsp_utils = require("refactoring.lsp_utils")

local ts = require("refactoring.ts")

local M = {}

function M.inline_var(bufnr, opts)
    Pipeline
        :from_task(refactor_setup(bufnr, opts)) -- 1. ensure LSP is available
        :add_task(function(refactor)
            -- TODO: don't remember how to get window id
            local current_node = ts.get_node_at_cursor(0)

            local definition = ts.find_definition(current_node, bufnr)
            local references = ts.find_references(
                definition,
                nil,
                bufnr,
                definition
            )

            local declarator_node = refactor.ts.get_container(
                definition,
                refactor.ts.variable_scope
            )

            local value_node = refactor.ts:local_var_values(declarator_node)

            local text_edits = {}
            table.insert(
                text_edits,
                lsp_utils.delete_text(Region:from_node(declarator_node, bufnr))
            )

            local value_text = ts.get_node_text(value_node, bufnr)

            if current_node:type() ~= "identifier" then
                error("Error: node under cursor is not an identifier")
            end

            for _, ref in pairs(references) do
                -- TODO: In my mind, if nothing is left on the line when you remove, it should get deleted.
                -- Could be done via opts into replace_text.
                local insert_text, delete_text = lsp_utils.replace_text(
                    Region:from_node(ref),
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
