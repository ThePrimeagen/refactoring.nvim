local M = {}

local api = vim.api

local TreeSitter = require("refactoring.treesitter")
local Point = require("refactoring.point")
local ui = require("refactoring.ui")
local Pipeline = require("refactoring.pipeline")

function M.not_ready()
    return false,
        "Sorry this refactor is not ready yet!  But I appreciate you very much :)"
end

---@param input_bufnr integer
---@param region_type 'v' | 'V' | '' | nil
---@param config refactor.Config
---@return refactor.Refactor
function M.refactor_seed(input_bufnr, region_type, config)
    local bufnr ---@type integer
    local test_bufnr = config:get_test_bufnr()
    if test_bufnr ~= nil then
        bufnr = test_bufnr
    else
        bufnr = input_bufnr
    end

    local ts, lang = TreeSitter.get_treesitter(bufnr)
    local ft = vim.bo[bufnr].filetype --[[@as refactor.ft]]

    local root = ts:get_root()
    local win = api.nvim_get_current_win()
    local cursor = Point:from_cursor()

    ---@class refactor.Refactor
    ---@field region? refactor.Region
    ---@field region_node? TSNode
    ---@field identifier_node? TSNode
    ---@field scope? TSNode
    ---@field text_edits? refactor.TextEdit[] | {bufnr?: integer}[]
    ---@field code refactor.CodeGeneration
    ---@field success_message? string
    local refactor = {
        ---@type {cursor: integer, func_call: integer|nil}
        whitespace = {
            cursor = assert(vim.fn.indent(cursor.row)),
        },
        cursor = cursor,
        code = config:get_code_generation_for(lang) --[[@as refactor.CodeGeneration]],
        ts = ts,
        filetype = ft,
        lang = lang,
        bufnr = bufnr,
        win = win,
        root = root,
        config = config,
        buffers = { bufnr },
        region_type = region_type,
    }

    return refactor
end

---@param bufnr integer
---@param ns integer
---@param edit_set refactor.TextEdit[]
local function preview_highlight(bufnr, ns, edit_set)
    api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    for _, edit in pairs(edit_set) do
        if edit.newText == "" then
            api.nvim_buf_set_extmark(
                bufnr,
                ns,
                edit.range.start.line,
                edit.range.start.character,
                {
                    end_row = edit.range.start.line + 1,
                    end_col = 0,
                    hl_eol = true,
                    strict = false,
                    hl_group = "Substitute",
                    right_gravity = false,
                    end_right_gravity = true,
                }
            )
        else
            api.nvim_buf_set_extmark(
                bufnr,
                ns,
                edit.range.start.line,
                edit.range.start.character,
                {
                    end_col = edit.range["end"].character,
                    strict = false,
                    hl_group = "Substitute",
                    right_gravity = false,
                    end_right_gravity = true,
                }
            )
        end
    end
end

---@param refactor refactor.Refactor
---@return true, refactor.Refactor
function M.refactor_apply_text_edits(refactor)
    if not refactor.text_edits then
        return true, refactor
    end

    ---@type table<integer, refactor.TextEdit[]>
    local edits = {}

    for _, edit in pairs(refactor.text_edits) do
        local bufnr = edit.bufnr or refactor.buffers[1]
        if not edits[bufnr] then
            edits[bufnr] = {}
        end

        table.insert(edits[bufnr], edit)
    end

    local ns = refactor.config:get()._preview_namespace

    for bufnr, edit_set in pairs(edits) do
        if ns then
            preview_highlight(bufnr, ns, edit_set)
        end
        vim.lsp.util.apply_text_edits(edit_set, bufnr, "utf-16")
    end

    return true, refactor
end

---@param refactor refactor.Refactor
---@return boolean, refactor.Refactor|string
function M.create_file_from_input(refactor)
    local file_name = ui.input("Create File: Name > ", vim.fn.expand("%:h"))
    if not file_name or file_name == "" then
        return false, "Error: Must provide a file name"
    end

    local starting_win = api.nvim_get_current_win()

    local new_bufnr = vim.fn.bufnr(vim.fn.expand(file_name))
    local new_winnr = vim.fn.bufwinnr(new_bufnr)
    if new_winnr == -1 then
        -- TODO: OPTIONS? We should probably configure this
        -- extract on second method added
        vim.cmd.vsplit(file_name)
        vim.opt_local.filetype = refactor.filetype
    else
        vim.cmd.wincmd({ args = { "w" }, count = new_winnr })
    end
    table.insert(refactor.buffers, api.nvim_get_current_buf())

    api.nvim_set_current_win(starting_win)
    return true, refactor
end

---@param refactor refactor.Refactor
---@param code_gen_operations string[]
---@return boolean, refactor.Refactor|string
function M.ensure_code_gen(refactor, code_gen_operations)
    for _, code_gen_operation in ipairs(code_gen_operations) do
        if refactor.code[code_gen_operation] == nil then
            return false,
                ("No %s function for code generator for %s"):format(
                    code_gen_operation,
                    refactor.filetype
                )
        end
    end
    return true, refactor
end

---@param refactor refactor.Refactor
function M.operator_setup(refactor)
    local Region = require("refactoring.region")

    local region = Region:from_motion({
        bufnr = refactor.bufnr,
        include_end_of_line = refactor.ts.include_end_of_line,
        type = refactor.region_type,
    })
    local region_node = region:to_ts_node(refactor.ts:get_root())
    local ok, scope = pcall(refactor.ts.get_scope, refactor.ts, region_node)
    if not ok then
        return ok, scope
    end

    refactor.region = region
    refactor.region_node = region_node
    refactor.scope = scope

    if refactor.scope == nil then
        return false, "Scope is nil"
    end

    return true, refactor
end

---@param refactor refactor.Refactor
local function success_message(refactor)
    local config = refactor.config:get()
    if refactor.success_message and config.show_success_message then
        vim.notify(
            refactor.success_message,
            vim.log.levels.INFO,
            { title = "refactoring.nvim" }
        )
    end
    return true, refactor
end

function M.post_refactor()
    return Pipeline:from_task(M.refactor_apply_text_edits)
        :add_task(success_message)
end

-- needed when another file is generated
function M.multiple_files_post_refactor()
    return Pipeline:from_task(M.refactor_apply_text_edits)
        :add_task(
            ---@param refactor refactor.Refactor
            ---@return boolean, refactor.Refactor
            function(refactor)
                api.nvim_set_current_win(refactor.win)
                return true, refactor
            end
        )
        :add_task(success_message)
end

return M
