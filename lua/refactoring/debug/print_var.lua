local Pipeline = require("refactoring.pipeline")
local Region = require("refactoring.region")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local post_refactor = require("refactoring.tasks.post_refactor")
local text_edits_utils = require("refactoring.text_edits_utils")
local debug_utils = require("refactoring.debug.debug_utils")
local ensure_code_gen = require("refactoring.tasks.ensure_code_gen")
local get_select_input = require("refactoring.get_select_input")
local indent = require("refactoring.indent")
local notify = require("refactoring.notify")

local api = vim.api

local M = {}

---@param opts c
---@param refactor Refactor
---@return string|nil
function M.get_print_var_statement(opts, refactor)
    local default_print_var_statement =
        refactor.code.default_print_var_statement()

    local custom_print_var_statements =
        opts.print_var_statements[refactor.filetype]

    --- @type string|nil
    local print_var_statement

    if custom_print_var_statements then
        if #custom_print_var_statements > 1 then
            print_var_statement = get_select_input(
                custom_print_var_statements,
                "print_var: Select a statement to insert:",
                ---@param item string
                ---@return string
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
    return print_var_statement
end

---@param bufnr integer
---@param config Config
function M.print_debug(bufnr, config)
    Pipeline:from_task(refactor_setup(bufnr, config))
        :add_task(
            ---@param refactor Refactor
            function(refactor)
                return ensure_code_gen(refactor, { "print_var", "comment" })
            end
        )
        :add_task(
            ---@param refactor Refactor
            function(refactor)
                local opts = refactor.config:get()

                if opts.below == nil then
                    opts.below = true
                end
                opts._end = opts.below

                -- Get variable text
                local variable_region = Region:from_motion()
                local variable = variable_region:get_text()[1]

                -- use treesitter for languges like PHP
                -- NOTE: remove in case of allowing more than simply iw as a motion
                local node = vim.treesitter.get_node()
                if node == nil then
                    return false, "node is nil"
                end
                local node_text =
                    vim.treesitter.get_node_text(node, refactor.bufnr)
                if node_text == variable then
                    local current = node ---@type TSNode?
                    while
                        current
                        and refactor.ts.should_check_parent_node_print_var(
                            current
                        )
                    do
                        current = current:parent()
                    end
                    if current == nil then
                        return false, "current is nil"
                    end
                    variable =
                        vim.treesitter.get_node_text(current, refactor.bufnr)
                end

                if variable == nil then
                    return false, "variable is nil"
                end

                local insert_pos, path_pos, current_statement =
                    debug_utils.get_debug_points(refactor, opts)

                assert(current_statement)
                local start_row = current_statement:range()
                local statement_row = start_row
                local statement_line = api.nvim_buf_get_lines(
                    refactor.bufnr,
                    statement_row,
                    statement_row + 1,
                    true
                )[1]
                local indent_amount =
                    indent.line_indent_amount(statement_line, refactor.bufnr)
                local indentation = indent.indent(indent_amount, refactor.bufnr)

                local ok, debug_path =
                    pcall(debug_utils.get_debug_path, refactor, path_pos)
                if not ok then
                    return ok, debug_path
                end
                local prefix = string.format("%s %s:", debug_path, variable)

                local print_var_statement =
                    M.get_print_var_statement(opts, refactor)

                if print_var_statement == nil then
                    return false, "print_var_statement is nill"
                end

                local print_statement = refactor.code.print_var({
                    statement = print_var_statement,
                    prefix = prefix,
                    var = variable,
                })
                local start_comment =
                    refactor.code.comment("__AUTO_GENERATED_PRINT_VAR_START__")
                local end_comment =
                    refactor.code.comment("__AUTO_GENERATED_PRINT_VAR_END__")

                local text = table.concat({
                    indentation,
                    start_comment,
                    "\n",
                    indentation,
                    print_statement,
                    " ",
                    end_comment,
                }, "")

                refactor.text_edits = {
                    text_edits_utils.insert_new_line_text(
                        Region:from_point(insert_pos),
                        text,
                        opts
                    ),
                }

                return true, refactor
            end
        )
        :after(post_refactor.post_refactor)
        :run(nil, notify.error)
end

return M
