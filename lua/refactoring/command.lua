local M = {}

--- @alias command_opts {name: string, args: string, fargs: string[], bang: boolean, line1: number, line2: number, range: number, count: number, reg: string, mods: string, smods: string[]}

local DO_NOT_PREVIEW = 0
local PREVIEW_IN_CURRENT_BUFFER = 1

local _needed_args = {
    inline_var = 0,
    inline_func = 0,
    extract_to_file = 2,
    extract_block_to_file = 2,
    default = 1,
}

--- @param opts command_opts
--- @param ns integer
local function command_preview(opts, ns)
    local refactors = require("refactoring.refactor")

    local refactor = opts.fargs[1]

    refactor = refactors[refactor] and refactor

    if not refactor then
        return DO_NOT_PREVIEW
    end

    local aditional_args = #opts.fargs - 1
    local needed_args = _needed_args[refactor] or _needed_args.default

    if aditional_args ~= needed_args then
        return DO_NOT_PREVIEW
    end

    -- TODO (TheLeoP): remove this once a response is given on https://github.com/neovim/neovim/issues/24330
    if refactor:find("file") then
        return DO_NOT_PREVIEW
    end

    for i = 2, needed_args + 1 do
        if opts.fargs[i] == "" then
            return DO_NOT_PREVIEW
        end
    end

    --- @type string[]
    local args = {}
    for i = 2, needed_args + 1 do
        table.insert(args, opts.fargs[i])
    end
    require("refactoring.config"):get():automate_input(args)

    require("refactoring").refactor(refactor, { _preview_namespace = ns })

    return PREVIEW_IN_CURRENT_BUFFER
end

--- @param opts command_opts
local function command(opts)
    local refactor = opts.fargs[1]

    if not refactor then
        return
    end

    local needed_args = _needed_args[refactor] or _needed_args.default

    --- @type string[]
    local args = {}
    for i = 2, needed_args + 1 do
        table.insert(args, opts.fargs[i])
    end

    require("refactoring.config"):get():automate_input(args)
    require("refactoring").refactor(refactor)
end

---@param arg_lead string
---@param cmd_line string
---@param _cursor_pos integer
---@return string[]
local function command_complete(arg_lead, cmd_line, _cursor_pos)
    local refactors = require("refactoring.refactor")

    local number_of_arguments = #vim.split(cmd_line, " ", { trimempty = true })

    if number_of_arguments > 2 then
        return {}
    end

    local options = vim.iter(vim.tbl_keys(refactors))
        :filter(
            --- @param option any
            function(option)
                return type(option) == "string"
            end
        )
        :filter(
            --- @param name string
            function(name)
                return vim.startswith(name, arg_lead)
            end
        )
        :totable()

    return options
end

function M.setup()
    vim.api.nvim_create_user_command(
        "Refactor",
        command,
        -- stylua: ignore start
        {
            nargs = "*",
            range = "%",
            preview = command_preview,
            complete = command_complete,
            desc = "Command entrypoint for refactoring.nvim",
            force = true,
        }
    )
end

return M
