local LspDefinition = require("refactoring.lsp")
local Pipeline = require("refactoring.pipeline")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local post_refactor = require("refactoring.tasks.post_refactor")
local Config = require("refactoring.config")

local M = {}

function M.replace_temp_with_query(bufnr)
    Pipeline
        :from_task(refactor_setup(bufnr, Config.get_config()))
        :add_task(function(refactor)
            -- TODO: I don't know if I solved this one yet or not
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
