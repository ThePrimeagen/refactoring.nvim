--[[
local Region = require("refactoring.region")
local get_input = require("refactoring.get_input")
local Query = require("refactoring.query")
]]
local ensure_lsp = require("refactoring.tasks.ensure_lsp")
local lsp_definition_setup = require("refactoring.tasks.lsp_definition_setup")
local Pipeline = require("refactoring.pipeline")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local not_ready = require("refactoring.tasks.not_ready")
local post_refactor = require("refactoring.tasks.post_refactor")
local Config = require("refactoring.config")
local ensure_lsp_definition_in_buffer = require(
    "refactoring.tasks.ensure_lsp_definition_in_buffer"
)

local M = {}

function M.inline_var(bufnr)
    Pipeline
        :from_task(refactor_setup(bufnr, Config.get_config()))
        :add_task(ensure_lsp)
        :add_task(lsp_definition_setup)
        :add_task(ensure_lsp_definition_in_buffer) -- java much?
        :add_task(not_ready)
        :add_task(function(refactor)
            -- 1. ensure LSP is available

            --[[
            local foo = 5
            local inline_node = refactor.root:named_descendant_for_range(
                refactor.lsp_definition_region:to_ts()
            )
            local parent_node = inline_node:parent()
            ]]
            return true, refactor
        end)
        :after(post_refactor)
        :run()
end

return M
