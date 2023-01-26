local Pipeline = require("refactoring.pipeline")
local Point = require("refactoring.point")
local Region = require("refactoring.region")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local post_refactor = require("refactoring.tasks.post_refactor")
local lsp_utils = require("refactoring.lsp_utils")
local ts_utils = require("nvim-treesitter.ts_utils")
local parsers = require("nvim-treesitter.parsers")
local debug_utils = require("refactoring.debug.debug_utils")
local ensure_code_gen = require("refactoring.tasks.ensure_code_gen")
local get_select_input = require("refactoring.get_select_input")
local utils = require("refactoring.utils")
local indent = require("refactoring.indent")

local function get_variable(opts, point)
    if opts.normal then
        local bufnr = 0
        local root_lang_tree = parsers.get_parser(bufnr)
        local row = point.row
        local col = point.col
        local lang_tree = root_lang_tree:language_for_range({
            point.row,
            point.col,
            point.row,
            point.col,
        })
        for _, tree in ipairs(lang_tree:trees()) do
            local root = tree:root()
            if root and ts_utils.is_in_node_range(root, row, col) then
                root:named_descendant_for_range(row, col, row, col)
            end
        end
        local node = ts_utils.get_node_at_cursor()
        local filetype = vim.bo[bufnr].filetype
        -- TODO: Can we do something with treesitter files here?
        if filetype == "php" then
            return "$" .. utils.get_node_text(node)[1]
        end
        return utils.get_node_text(node)[1]
    end
    local variable_region = Region:from_current_selection()
    return variable_region:get_text()[1]
end

local function printDebug(bufnr, config)
    return Pipeline:from_task(refactor_setup(bufnr, config))
        :add_task(function(refactor)
            return ensure_code_gen(refactor, { "print_var", "comment" })
        end)
        :add_task(function(refactor)
            local opts = refactor.config:get()
            local point = Point:from_cursor()

            -- always go below for text
            opts.below = true
            point.col = opts.below and 100000 or 1

            if opts.normal == nil then
                opts.normal = false
            end

            -- Get variable text
            local variable = get_variable(opts, point)
            local indentation
            if refactor.ts.allows_indenting_task then
                local indent_amount = indent.buf_indent_amount(
                    refactor.cursor,
                    refactor,
                    opts.below,
                    refactor.bufnr
                )
                indentation = indent.indent(indent_amount, refactor.bufnr)
            end

            local debug_path = debug_utils.get_debug_path(refactor, point)
            local prefix = string.format("%s %s:", debug_path, variable)

            local default_print_var_statement =
                refactor.code.default_print_var_statement()

            local custom_print_var_statements =
                opts.print_var_statements[refactor.filetype]

            local print_var_statement

            if custom_print_var_statements then
                if #custom_print_var_statements > 1 then
                    print_var_statement = get_select_input(
                        custom_print_var_statements,
                        "print_var: Select a statement to insert:",
                        function(item)
                            return item
                        end
                    )
                else
                    print_var_statement = custom_print_var_statements[1]
                end
            else
                print_var_statement = default_print_var_statement[1]
            end

            local print_var_opts = {
                statement = print_var_statement,
                prefix = prefix,
                var = variable,
            }

            local print_statement = refactor.code.print_var(print_var_opts)

            local statement
            if indentation ~= nil then
                local temp = {}
                temp[1] = indentation
                temp[2] = print_statement
                statement = table.concat(temp, "")
            else
                statement = print_statement
            end

            refactor.text_edits = {
                lsp_utils.insert_new_line_text(
                    Region:from_point(point),
                    statement
                        .. " "
                        .. refactor.code.comment("__AUTO_GENERATED_PRINT_VAR__"),
                    opts
                ),
            }

            return true, refactor
        end)
        :after(post_refactor.post_refactor)
        :run()
end

return printDebug
