local refactors = require("refactoring.refactor")
local Config = require("refactoring.config")
local get_select_input = require("refactoring.get_select_input")
local async = require("plenary.async")

local M = {}

function M.setup(config)
    Config.setup(config)
end

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

    -- Remove the calls to vim.fn
    -- I just forgot the name of this ;)
    local config = Config.get():merge(opts)
    refactors[refactor](vim.api.nvim_buf_get_number(0), config)
end

function M.get_refactors()
    return vim.tbl_keys(refactors.refactor_names)
end

function M.select_refactor(opts)
    local selected_refactor

    async.run(function()
        selected_refactor = get_select_input(
            M.get_refactors(),
            "Refactoring: select a refactor to apply:"
        )
    end)

    if selected_refactor then
        M.refactor(selected_refactor, opts)
    end
end

M.debug = require("refactoring.debug")

return M
