local api = vim.api
local refactors = require("refactoring.refactor")

local M = {}

local dont_need_args = {
    "Inline Variable",
    "Inline Function",
}

---@param config ConfigOpts
function M.setup(config)
    require("refactoring.config").setup(config)
end

---@alias refactor.RefactorFunc fun(bufnr: integer, type: 'v' | 'V' | '' | nil, opts: Config)

local last_refactor ---@type refactor.RefactorFunc
local last_config ---@type Config

---@param type "line" | "char" | "block"
function M.refactor_operatorfunc(type)
    local region_type = type == "line" and "V"
        or type == "char" and "v"
        or type == "block" and ""
        or nil
    last_refactor(api.nvim_get_current_buf(), region_type, last_config)
end

local default_motions = {
    [refactors.inline_var] = "iw",
    [refactors.inline_func] = "iw",
    [refactors.extract_block] = "l",
}

---@param name string|number
---@param opts ConfigOpts|nil
function M.refactor(name, opts)
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
    last_config = Config.get():merge(opts)
    last_refactor = refactors[refactor]

    vim.o.operatorfunc = "v:lua.require'refactoring'.refactor_operatorfunc"

    local mode = api.nvim_get_mode().mode
    if mode ~= "n" then
        return "g@"
    end

    local default_motion = default_motions[last_refactor]
    if not default_motion then
        return "g@"
    end
    return "g@" .. default_motion
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
        local ui = require("refactoring.ui")
        local selected_refactor = ui.select(
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
