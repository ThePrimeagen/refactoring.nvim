local Pipeline = require("refactoring.pipeline")
local Point = require("refactoring.point")
local Region = require("refactoring.region")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local post_refactor = require("refactoring.tasks.post_refactor")
local lsp_utils = require("refactoring.lsp_utils")
local debug_utils = require("refactoring.debug.debug_utils")
local ensure_code_gen = require("refactoring.tasks.ensure_code_gen")
local get_select_input = require("refactoring.get_select_input")
local utils = require("refactoring.utils")
local indent = require("refactoring.indent")

local MAX_COL = 100000

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

---@param opts table
---@param point RefactorPoint
---@param refactor Refactor
---@return string|nil identifier
local function get_variable(opts, point, refactor)
    if opts.normal then
        local bufnr = 0
        local lang = vim.treesitter.language.get_lang(refactor.filetype)
        local root_lang_tree = vim.treesitter.get_parser(bufnr, lang)
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
            if root and vim.treesitter.is_in_node_range(root, row, col) then
                root:named_descendant_for_range(row, col, row, col)
            end
        end
        local node = vim.treesitter.get_node()

        if node == nil then
            return nil
        end

        --- @type TSNode
        local parent_node = node:parent()
        if refactor.ts.should_check_parent_node(parent_node:type()) then
            node = parent_node
        end

        return table.concat(utils.get_node_text(node), "")
    end
    vim.cmd("norm! ")
    local variable_region = Region:from_current_selection()
    return variable_region:get_text()[1]
end

---@param bufnr integer
---@param config Config
function M.printDebug(bufnr, config)
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
                local point = Point:from_cursor()

                -- always go below for text
                opts.below = true
                -- always go end for text
                opts._end = true
                point.col = opts.below and MAX_COL or 1

                local mode = vim.api.nvim_get_mode().mode
                opts.normal = mode == "n"

                -- Get variable text
                local variable = get_variable(opts, point, refactor)

                if variable == nil then
                    return false, "variable is nil"
                end

                --- @type string
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

                --- @type string
                local statement
                if indentation ~= nil then
                    statement =
                        table.concat({ indentation, print_statement }, "")
                else
                    statement = print_statement
                end

                refactor.text_edits = {
                    lsp_utils.insert_new_line_text(
                        Region:from_point(point),
                        refactor.code.comment(
                            "__AUTO_GENERATED_PRINT_VAR_START__"
                        )
                            .. "\n"
                            .. statement
                            .. " "
                            .. refactor.code.comment(
                                "__AUTO_GENERATED_PRINT_VAR_END__"
                            ),
                        opts
                    ),
                }

                return true, refactor
            end
        )
        :after(post_refactor.post_refactor)
        :run()
end

return M
