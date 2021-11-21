local Pipeline = require("refactoring.pipeline")
local Point = require("refactoring.point")
local Region = require("refactoring.region")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local post_refactor = require("refactoring.tasks.post_refactor")
local lsp_utils = require("refactoring.lsp_utils")
local debug_utils = require("refactoring.debug.debug_utils")

local function get_variable()
    local variable_region = Region:from_current_selection()
    return variable_region:get_text()[1]
end

local function printDebug(bufnr, config)
    return Pipeline
        :from_task(refactor_setup(bufnr, config))
        :add_task(function(refactor)
            local opts = refactor.config:get()
            local point = Point:from_cursor()
            local region = point:to_region()
            -- always go below for text
            opts.below = true
            point.col = opts.below and 100000 or 1

            -- Get variable text
            local variable = get_variable()

            -- TODO: Breakout getting path into common util
            local debug_path = debug_utils.get_debug_path(refactor, point)
            local prefix = string.format("%s %s:", debug_path, variable)

            -- TODO: Break this out into common utils and throw error
            local code_gen = debug_utils.get_code_gen(refactor, bufnr)
            local print_statement = code_gen.print_var(prefix, variable)

            refactor.text_edits = {
                lsp_utils.insert_new_line_text(region, print_statement, opts),
            }

            return true, refactor
        end)
        :after(post_refactor)
        :run()
end

return printDebug
