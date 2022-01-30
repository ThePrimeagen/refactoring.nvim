local Point = require("refactoring.point")
local Region = require("refactoring.region")

-- TODO: How to run on specific bufnr
local function indent_block(start_row, end_row, indent_amount)
    -- TODO: have to be a better way to do this
    vim.schedule(function()
        vim.cmd(":" .. start_row)
        -- TODO: Rename temp with real value
        local temp = (end_row + 1) - start_row
        local indent_cmd = "norm!V" .. temp .. "j" .. indent_amount .. "v_>"
        vim.cmd(indent_cmd)
    end)
end

local function reset_cursor(bufnr_shiftwidth, refactor, total_indents)
    local new_col = bufnr_shiftwidth * total_indents + 1
    vim.schedule(function()
        vim.api.nvim_win_set_cursor(refactor.win, {
            refactor.result_cursor_row,
            new_col,
        })
    end)
end

local function indent_func_call(refactor)
    -- TODO: Remove debug
    -- Get node for function call
    local func_call_node = Point
        :from_values(refactor.result_cursor_row, 0)
        :to_ts_node(refactor.ts:get_root())
    -- Get new scope for correct ancestory for indent diff
    local scope = refactor.ts:get_scope(func_call_node)
    local indent_diff = refactor.ts:indent_scope_difference(
        scope,
        func_call_node
    )

    -- Get shiftwidth of current bufnr
    local bufnr_shiftwidth = vim.bo.shiftwidth

    -- Is this correct? Have to test with python classes to be sure
    -- TODO: breakout to it's own func
    local scope_region = Region:from_node(scope, refactor.bufnr)
    local _, scope_start_col, _, _ = scope_region:to_vim()
    local baseline_indent = math.floor(scope_start_col / bufnr_shiftwidth)

    local total_indents = baseline_indent + indent_diff

    local func_call_start_row, _, _, _ = Region
        :from_node(func_call_node, refactor.bufnr)
        :to_vim()
    indent_block(func_call_start_row, func_call_start_row, total_indents)

    reset_cursor(bufnr_shiftwidth, refactor, total_indents)
end

local function indent(refactor)
    -- TODO: How to limit to only extract func for now...
    if refactor.ts:allows_indenting_task() and refactor.operation == 106 then
        print("Hitting indent!")
        indent_func_call(refactor)
    end

    return true, refactor
end
return indent
