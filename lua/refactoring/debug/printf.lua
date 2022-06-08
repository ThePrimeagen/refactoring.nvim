local Pipeline = require("refactoring.pipeline")
local Point = require("refactoring.point")
local Region = require("refactoring.region")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local post_refactor = require("refactoring.tasks.post_refactor")
local lsp_utils = require("refactoring.lsp_utils")
local debug_utils = require("refactoring.debug.debug_utils")
local ensure_code_gen = require("refactoring.tasks.ensure_code_gen")
local get_select_input = require("refactoring.get_select_input")

local function get_indent_amount(refactor)
    return refactor.whitespace.cursor / refactor.whitespace.tabstop
end

local function printDebug(bufnr, config)
    return Pipeline
        :from_task(refactor_setup(bufnr, config))
        :add_task(function(refactor)
            return ensure_code_gen(refactor, { "print", "comment" })
        end)
        :add_task(function(refactor)
            local opts = refactor.config:get()
            local point = Point:from_cursor()

            -- set default `below` behavior
            if opts.below == nil then
                opts.below = true
            end
            point.col = opts.below and 100000 or 1

            local indent
            if refactor.ts.allows_indenting_task then
                local indent_amount = get_indent_amount(refactor)
                indent = refactor.code.indent({
                    indent_width = refactor.whitespace.tabstop,
                    indent_amount = indent_amount,
                })
            end

            local debug_path = debug_utils.get_debug_path(refactor, point)

            local default_printf_statement =
                refactor.code.default_printf_statement()

            local custom_printf_statements =
                opts.printf_statements[refactor.filetype]

            local printf_statement

            -- if there's a set of statements given for this one
            if custom_printf_statements then
                if #custom_printf_statements > 1 then
                    printf_statement = get_select_input(
                        custom_printf_statements,
                        "printf: Select a statement to insert:",
                        function(item)
                            return item
                        end
                    )
                else
                    printf_statement = custom_printf_statements[1]
                end
            else
                printf_statement = default_printf_statement[1]
            end

            local printf_opts = {
                statement = printf_statement,
                content = debug_path,
            }

            local statement
            if indent ~= nil then
                local temp = {}
                temp[1] = indent
                temp[2] = refactor.code.print(printf_opts)
                statement = table.concat(temp, "")
            else
                statement = refactor.code.print(printf_opts)
            end

            refactor.text_edits = {
                lsp_utils.insert_new_line_text(
                    Region:from_point(point),
                    statement
                        .. " "
                        .. refactor.code.comment("__AUTO_GENERATED_PRINTF__"),
                    opts
                ),
            }

            return true, refactor
        end)
        :after(post_refactor.post_refactor)
        :run()
end

return printDebug
