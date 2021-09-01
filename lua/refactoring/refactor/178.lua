local LspDefinition = require("refactoring.lsp")
local ensure_lsp = require("refactoring.tasks.ensure_lsp")
local Pipeline = require("refactoring.pipeline")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local post_refactor = require("refactoring.tasks.post_refactor")
local Config = require("refactoring.config")

local M = {}

function M.replace_temp_with_query(bufnr)
    Pipeline
        :from_task(refactor_setup(bufnr, Config.get_config()))
        :add_task(ensure_lsp)
        :add_task(function(refactor)
            local lsp_definition = LspDefinition:from_cursor(
                bufnr,
                refactor.query
            )

            return true, refactor, lsp_definition
        end)
        :after(post_refactor)
        :run()
end

return M
