local Pipeline = require("refactoring.pipeline")
local Point = require("refactoring.point")
local Region = require("refactoring.region")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local post_refactor = require("refactoring.tasks.post_refactor")
local lsp_utils = require("refactoring.lsp_utils")

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
            -- always go below for text
            opts.below = true
            point.col = opts.below and 100000 or 1
            local region = point:to_region()

            -- Get variable text
            local variable = get_variable()

            -- TODO: Breakout getting path into common util
            local node = point:to_ts_node(refactor.ts:get_root())
            local debug_path = refactor.ts:get_debug_path(node)

            local path = {}
            for i = #debug_path, 1, -1 do
                table.insert(path, tostring(debug_path[i]))
            end
            local debug_path_concat = table.concat(path, "#")

            local prefix = string.format("%s %s:", debug_path_concat, variable)

            -- TODO: Break this out into common utils and throw error
            local code_gen = refactor.config:get_code_generation_for()
            if not code_gen then
                return false,
                    string.format("No code generator for %s", vim.bo[bufnr].ft)
            end
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

