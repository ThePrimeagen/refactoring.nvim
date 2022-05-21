local Pipeline = require("refactoring.pipeline")
local Point = require("refactoring.point")
local Region = require("refactoring.region")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local post_refactor = require("refactoring.tasks.post_refactor")
local lsp_utils = require("refactoring.lsp_utils")
local ts_utils = require("nvim-treesitter.ts_utils")
local parsers = require "nvim-treesitter.parsers"
local debug_utils = require("refactoring.debug.debug_utils")
local ensure_code_gen = require("refactoring.tasks.ensure_code_gen")
local get_select_input = require("refactoring.get_select_input")

local function get_variable()
    local variable_region = Region:from_current_selection()
    if variable_region.start_col == 0
      and variable_region.end_col == 0
      and variable_region.start_row == 0
      and variable_region.end_row == 0
    then
        local bufnr = 0
        local root_lang_tree = parsers.get_parser(bufnr)
        local current_pos = Point:from_cursor()
        local line = current_pos.row
        local col = current_pos.col
        variable_region.start_row = current_pos.row
        local lang_tree = root_lang_tree:language_for_range { current_pos.row, current_pos.col,
        current_pos.row, current_pos.col }
        -- TODO: IDK :D
        for _, tree in ipairs(lang_tree:trees()) do
            local root = tree:root()
            if root and ts_utils.is_in_node_range(root, current_pos.row, col) then
              local node = root:named_descendant_for_range(line, col, line, col)
              print(ts_utils.get_next_node(node))
            end
        end
        local node = ts_utils.get_node_at_cursor()
        return ts_utils.get_node_text(node)[1]
    end
    return variable_region:get_text()[1]
end

local function printDebug(bufnr, config)
    return Pipeline
        :from_task(refactor_setup(bufnr, config))
        :add_task(function(refactor)
            return ensure_code_gen(refactor, { "print_var", "comment" })
        end)
        :add_task(function(refactor)
            local opts = refactor.config:get()
            local point = Point:from_cursor()

            -- always go below for text
            opts.below = true
            point.col = opts.below and 100000 or 1

            -- Get variable text
            local variable = get_variable()

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
                .. refactor.code.comment("__AUTO_GENERATED_PRINT_VAR__")

            refactor.text_edits = {
                lsp_utils.insert_new_line_text(
                    Region:from_point(point),
                    print_statement,
                    opts
                ),
            }

            return true, refactor
        end)
        :after(post_refactor.post_refactor)
        :run()
end

return printDebug
