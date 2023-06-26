local refactors = require("refactoring.refactor")
local Config = require("refactoring.config")

local M = {}

--- @alias command_opts {name: string, args: string, fargs: string[], bang: boolean, line1: number, line2: number, range: number, count: number, reg: string, mods: string, smods: string[]}

local PREVIEW_IN_CURRENT_BUFFER = 1

--- @param opts command_opts
--- @param ns integer
local function command_preview(opts, ns)
    local refactor = tonumber(opts.fargs[1]) or opts.fargs[1]
    local input = opts.fargs[2]

    refactor = refactors.refactor_names[refactor]
        or refactors[refactor] and refactor

    if refactor then
        if
            (refactor ~= 123 and refactor ~= "inline_var")
            and (not input or input == "")
        then
            return PREVIEW_IN_CURRENT_BUFFER
        end
        Config:get():automate_input(input)
        require("refactoring").refactor(refactor, { _preview_namespace = ns })
    end
    return PREVIEW_IN_CURRENT_BUFFER
end

--- @param opts command_opts
local function command(opts)
    local refactor = tonumber(opts.fargs[1]) or opts.fargs[1]
    local input = opts.fargs[2]

    refactor = refactors.refactor_names[refactor]
        or refactors[refactor] and refactor

    if input then
        Config:get():automate_input(input)
    end
    require("refactoring").refactor(refactor)
end

---@param arg_lead string
---@param cmd_line string
---@param _cursor_pos integer
---@return string[]
local function command_complete(arg_lead, cmd_line, _cursor_pos)
    local number_of_arguments = #vim.split(cmd_line, " ")

    if number_of_arguments > 2 then
        return {}
    end

    local options = vim.tbl_map(
        --- @param option any
        function(option)
            return tostring(option)
        end,
        vim.tbl_keys(refactors)
    )

    local filtered_options = vim.tbl_filter(
        --- @param name string
        function(name)
            return vim.startswith(name, arg_lead)
        end,
        options
    )

    return filtered_options
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
