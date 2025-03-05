local api = vim.api

local M = {}

local dont_need_args = {
    "Inline Variable",
    "Inline Function",
}

---@param config ConfigOpts
function M.setup(config)
    require("refactoring.config").setup(config)
end

---@param name string|number
---@param opts ConfigOpts|nil
function M.refactor(name, opts)
    local refactors = require("refactoring.refactor")
    if opts == nil then
        opts = {}
    end

    local refactor = refactors.refactor_names[name] or refactors[name] and name
    if not refactor then
        error(
            ('Could not find refactor %s.  You can get a list of all refactors from require("refactoring").get_refactors()'):format(
                refactor
            )
        )
    end

    local Config = require("refactoring.config")
    local config = Config.get():merge(opts)
    refactors[refactor](api.nvim_get_current_buf(), config)
end

---@return string[]
function M.get_refactors()
    local refactors = require("refactoring.refactor")
    return vim.tbl_keys(
        refactors.refactor_names --[[@as table<string, string>>]]
    )
end

---@param opts ConfigOpts|{prefer_ex_cmd: boolean?}?
function M.select_refactor(opts)
    local prefer_ex_cmd = opts and opts.prefer_ex_cmd or false

    -- vim.ui.select exits visual mode without setting the `<` and `>` marks
    local utils = require("refactoring.utils")
    if utils.is_visual_mode() then
        utils.exit_to_normal_mode()
    end

    require("plenary.async").void(function()
        local selected_refactor = require("refactoring.get_select_input")(
            M.get_refactors(),
            "Refactoring: select a refactor to apply:"
        )

        if not selected_refactor then
            return
        end

        if
            prefer_ex_cmd
            and not vim.list_contains(dont_need_args, selected_refactor)
        then
            local refactor_name =
                require("refactoring.refactor").refactor_names[selected_refactor]
            api.nvim_input((":Refactor %s "):format(refactor_name))
        else
            M.refactor(selected_refactor, opts)
        end
    end)()
end

M.debug = require("refactoring.debug")

return M
