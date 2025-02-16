local M = {}

local _dont_need_args = {
    "inline_var",
    "inline_func",
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
            string.format(
                'Could not find refactor %s.  You can get a list of all refactors from require("refactoring").get_refactors()',
                refactor
            )
        )
    end

    local Config = require("refactoring.config")
    local config = Config.get():merge(opts)
    refactors[refactor](vim.api.nvim_get_current_buf(), config)
end

---@return string[]
function M.get_refactors()
    local refactors = require("refactoring.refactor")
    return vim.tbl_keys(refactors.refactor_names)
end

---@param opts ConfigOpts
---@param useExCmd? boolean
function M.select_refactor(opts, useExCmd)
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

        if selected_refactor then
            local refactors = require("refactoring.refactor")
            local refactor = refactors.refactor_names[selected_refactor]
                or refactors[selected_refactor] and selected_refactor
            if not useExCmd or vim.list_contains(_dont_need_args, refactor) then
                M.refactor(selected_refactor, opts)
            else
                vim.api.nvim_input(":Refactor " .. refactor .. " ")
            end
        end
    end)()
end

M.debug = require("refactoring.debug")

return M
