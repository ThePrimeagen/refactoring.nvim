local refactors = require("refactoring.refactor")
local Config = require("refactoring.config")
local command = require("refactoring.command")
local get_select_input = require("refactoring.get_select_input")
local async = require("plenary.async")

local M = {}

---@param config ConfigOpts
function M.setup(config)
    Config.setup(config)
    command.setup()
end

---@param name string|number
---@param opts ConfigOpts|nil
function M.refactor(name, opts)
    if opts == nil then
        opts = {}
    end

    -- TODO: We should redo how this selection thing works.
    local refactor = refactors.refactor_names[name] or refactors[name] and name
    if not refactor then
        error(
            string.format(
                'Could not find refactor %s.  You can get a list of all refactors from require("refactoring").get_refactors()',
                refactor
            )
        )
    end

    local config = Config.get():merge(opts)
    refactors[refactor](vim.api.nvim_get_current_buf(), config)
end

---@return string[]
function M.get_refactors()
    return vim.tbl_keys(refactors.refactor_names)
end

---@param opts ConfigOpts
function M.select_refactor(opts)
    async.run(function()
        local selected_refactor = get_select_input(
            M.get_refactors(),
            "Refactoring: select a refactor to apply:"
        )

        if selected_refactor then
            M.refactor(selected_refactor, opts)
        end
    end)
end

M.debug = require("refactoring.debug")

return M
