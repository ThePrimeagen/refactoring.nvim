local Pipeline = require("refactoring.pipeline")
local Point = require("refactoring.point")
local Region = require("refactoring.region")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local post_refactor = require("refactoring.tasks.post_refactor")
local lsp_utils = require("refactoring.lsp_utils")
local debug_utils = require("refactoring.debug.debug_utils")
local ensure_code_gen = require("refactoring.tasks.ensure_code_gen")

local function printDebug(bufnr, config)
    return Pipeline
        :from_task(refactor_setup(bufnr, config))
        :add_task(function(refactor)
            return ensure_code_gen(refactor, { "print" })
        end)
        :add_task(function(refactor)
            local opts = refactor.config:get()
            local point = Point:from_cursor()

            -- set default `below` behavior
            if opts.below == nil then
                opts.below = true
            end
            point.col = opts.below and 100000 or 1

            local debug_path = debug_utils.get_debug_path(refactor, point)
            local print_statement = refactor.code.print(debug_path)

            refactor.text_edits = {
                lsp_utils.insert_new_line_text(
                    Region:from_point(point),
                    print_statement,
                    opts
                ),
            }

            return true, refactor
        end)
        :after(post_refactor)
        :run()
end

return printDebug
