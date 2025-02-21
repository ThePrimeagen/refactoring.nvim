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
---@return string
function M.get_printf_statement(opts, refactor)
    local default_printf_statement = refactor.code.default_printf_statement()

    local custom_printf_statements = opts.printf_statements[refactor.filetype]

    local printf_statement ---@type string

    -- if there's a set of statements given for this one
    if custom_printf_statements then
        if #custom_printf_statements > 1 then
            printf_statement = assert(
                get_select_input(
                    custom_printf_statements,
                    "printf: Select a statement to insert:"
                )
            )
        else
            printf_statement = custom_printf_statements[1]
        end
    else
        printf_statement = default_printf_statement[1]
    end
    return printf_statement
end

--- Add text edit for printf to be inserted (line above or below cursor).
--- Should always be called at least once
---@param refactor Refactor
---@param opts {below:boolean, _end:boolean}
---@param printf_statement string
---@param content string
---@param point RefactorPoint
local function text_edit_insert_text(
    refactor,
    opts,
    printf_statement,
    content,
    point
)
    local text = refactor.code.print({
        statement = printf_statement,
        content = content,
    })

    local _, _, current_statement = debug_utils.get_debug_points(refactor, opts)

    local start_row, _, end_row = current_statement:range()
    local statement_row = opts.below and start_row + 1 or end_row
    local statement_line = api.nvim_buf_get_lines(
        refactor.bufnr,
        statement_row,
        statement_row + 1,
        true
    )[1]
    local indent_amount =
        indent.line_indent_amount(statement_line, refactor.bufnr)
    local indentation = indent.indent(indent_amount, refactor.bufnr)

    local start_comment =
        refactor.code.comment("__AUTO_GENERATED_PRINTF_START__")
    local end_comment = refactor.code.comment("__AUTO_GENERATED_PRINTF_END__")

    text = table.concat({
        indentation,
        start_comment,
        "\n",
        indentation,
        text,
        " ",
        end_comment,
    }, "")

    local range = Region:from_point(point, refactor.bufnr)
    table.insert(
        refactor.text_edits,
        text_edits_utils.insert_new_line_text(range, text, opts)
    )
end

--- Add text edits for printf to be modified in the current buffer (to keep the count of each printf in sync).
--- Should be called for each line with a debug printf statement in the current buffer.
--
--- Checks if each line should be modified and only adds a text_edit if its needed
---@param refactor Refactor
---@param debug_path string
---@param escaped_printf_statement string
---@param lines string[]
---@param row_num integer
---@param i integer
local function text_edits_modify_count(
    refactor,
    debug_path,
    escaped_printf_statement,
    lines,
    row_num,
    i
)
    local escaped_debug_path = vim.pesc(debug_path)
    local count_pattern = debug_path ~= ""
            and escaped_debug_path .. " " .. "(%d+)"
        or "(%d+)"
    local before_count_pattern = debug_path ~= ""
            and escaped_debug_path .. " " .. "()%d+"
        or "()%d+"
    local after_count_pattern = debug_path ~= ""
            and escaped_debug_path .. " " .. "%d+()"
        or "%d+()"
    local pattern_count = refactor.code.print({
        statement = escaped_printf_statement,
        content = count_pattern,
    })
    local pattern_before = refactor.code.print({
        statement = escaped_printf_statement,
        content = before_count_pattern,
    })
    local pattern_after = refactor.code.print({
        statement = escaped_printf_statement,
        content = after_count_pattern,
    })

    local _, _, current_count = string.find(lines[row_num], pattern_count)
    local _start = string.match(lines[row_num], pattern_before)
    local _end = string.match(lines[row_num], pattern_after)

    local text = tostring(i)
    if current_count ~= text then
        local range = Region:from_values(
            refactor.bufnr,
            row_num,
            _start,
            row_num,
            _end - 1
        )
        table.insert(
            refactor.text_edits,
            text_edits_utils.replace_text(range, text)
        )
    end
end

---@param bufnr integer
---@param config Config
function M.printDebug(bufnr, config)
    Pipeline:from_task(refactor_setup(bufnr, config))
        :add_task(
            ---@param refactor Refactor
            function(refactor)
                return ensure_code_gen(refactor, { "print", "comment" })
            end
        )
        :add_task(
            ---@param refactor Refactor
            function(refactor)
                local opts = refactor.config:get()
                local cursor = refactor.cursor

                if opts.below == nil then
                    opts.below = true
                end
                opts._end = opts.below

                local insert_pos, path_pos =
                    debug_utils.get_debug_points(refactor, opts)

                local ok, debug_path =
                    pcall(debug_utils.get_debug_path, refactor, path_pos)
                if not ok then
                    return ok, debug_path
                end

                local printf_statement = M.get_printf_statement(opts, refactor)

                -- magic characters in lua
                -- ^$()%.[]*+-?
                -- we do not escape `%` because we need patterns like `%s` to work
                -- but, we escape `%%` because we need patterns like `%%d` to be ignored
                local escaped_printf_statement = printf_statement
                    :gsub("%%%%", "%%%%%1")
                    :gsub("([%^%$%(%)%[%]%*%+%-%?])", "%%%%%1")
                local text_to_count_pattern = debug_path ~= ""
                        and ("%s %%d+"):format(vim.pesc(debug_path))
                    or "%d+"
                local text_to_count = refactor.code.print({
                    statement = escaped_printf_statement,
                    content = text_to_count_pattern,
                })

                local lines =
                    api.nvim_buf_get_lines(refactor.bufnr, 0, -1, false)

                ---@type integer[]
                local current_lines_with_text = {}
                for row_num, line in ipairs(lines) do
                    if string.find(line, text_to_count) ~= nil then
                        table.insert(current_lines_with_text, row_num)
                    end
                end
                local should_replace = vim.tbl_contains(
                    current_lines_with_text,
                    cursor.row
                ) and opts.below
                table.insert(current_lines_with_text, cursor.row)
                table.sort(current_lines_with_text)

                refactor.text_edits = {}
                for i, row_num in ipairs(current_lines_with_text) do
                    ---@type string
                    local content
                    if debug_path ~= "" then
                        content = table.concat({ debug_path, tostring(i) }, " ")
                    else
                        content = tostring(i)
                    end

                    if row_num == cursor.row and not should_replace then
                        should_replace = true
                        local ok2, error = pcall(
                            text_edit_insert_text,
                            refactor,
                            opts,
                            printf_statement,
                            content,
                            insert_pos
                        )
                        if not ok2 then
                            return ok2, error
                        end
                    else
                        if row_num == cursor.row then
                            should_replace = false
                        end
                        text_edits_modify_count(
                            refactor,
                            debug_path,
                            escaped_printf_statement,
                            lines,
                            row_num,
                            i
                        )
                    end
                end

                return true, refactor
            end
        )
        :after(post_refactor.post_refactor)
        :run(nil, notify.error)
end

return M
