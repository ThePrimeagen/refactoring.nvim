local Pipeline = require("refactoring.pipeline")
local Point = require("refactoring.point")
local Region = require("refactoring.region")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local post_refactor = require("refactoring.tasks.post_refactor")
local lsp_utils = require("refactoring.lsp_utils")
local debug_utils = require("refactoring.debug.debug_utils")
local ensure_code_gen = require("refactoring.tasks.ensure_code_gen")
local get_select_input = require("refactoring.get_select_input")
local indent = require("refactoring.indent")

local function get_indent_amount(refactor, below)
    local region = Region:from_point(refactor.cursor)
    local region_node = region:to_ts_node(refactor.ts:get_root())

    local scope = refactor.ts:get_scope(region_node)

    local nodes = {}
    local statements = refactor.ts:get_statements(scope)
    for _, node in ipairs(statements) do
        table.insert(nodes, node)
    end
    local function_body = refactor.ts:get_function_body(scope)
    for _, node in ipairs(function_body) do
        table.insert(nodes, node)
    end

    local line_numbers = {}
    for _, node in ipairs(nodes) do
        local start_row, _, end_row, _ = node:range()
        table.insert(line_numbers, start_row + 1)
        table.insert(line_numbers, end_row + 1)
    end

    local hash = {}
    line_numbers = vim.tbl_filter(function(line_number)
        if hash[line_number] then
            return false
        end
        hash[line_number] = true
        local distance = refactor.cursor.row - line_number
        return distance ~= 0
    end, line_numbers)

    local line_numbers_up = vim.tbl_filter(function(line_number)
        local distance = refactor.cursor.row - line_number
        return distance > 0
    end, line_numbers)
    local line_numbers_down = vim.tbl_filter(function(line_number)
        local distance = refactor.cursor.row - line_number
        return distance < 0
    end, line_numbers)

    local sort = function(a, b)
        local a_distance = math.abs(refactor.cursor.row - a)
        local b_distance = math.abs(refactor.cursor.row - b)
        return a_distance < b_distance
    end
    table.sort(line_numbers_up, sort)
    table.sort(line_numbers_down, sort)

    local line_up = line_numbers_up[1]
    local line_down = line_numbers_down[1]

    local line_down_indent = vim.fn.indent(line_down)
    local line_up_indent = vim.fn.indent(line_up)
    local cursor_indent = vim.fn.indent(refactor.cursor.row)

    local indent_scope_whitespace
    if below then
        if cursor_indent == 0 then
            indent_scope_whitespace = math.max(line_down_indent, line_up_indent)
        else
            indent_scope_whitespace = math.max(cursor_indent, line_down_indent)
        end
    else
        if cursor_indent == 0 then
            indent_scope_whitespace = math.max(line_down_indent, line_up_indent)
        else
            indent_scope_whitespace = math.max(cursor_indent, line_up_indent)
        end
    end

    return indent_scope_whitespace / indent.buf_indent_width(refactor.bufnr)
end

local function printDebug(bufnr, config)
    return Pipeline:from_task(refactor_setup(bufnr, config))
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

            local indentation
            if refactor.ts:allows_indenting_task() then
                local indent_amount = get_indent_amount(refactor, opts.below)
                indentation = refactor.code.indent({
                    indent_width = indent.buf_indent_width(refactor.bufnr),
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
            if indentation ~= nil then
                local temp = {}
                temp[1] = indentation
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
