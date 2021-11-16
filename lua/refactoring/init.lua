local refactors = require("refactoring.refactor")
local Config = require("refactoring.config")

local M = {}

function M.setup(config)
    Config.setup(config)
end

function M.refactor(name, opts)
    local refactor = refactors.refactor_names[name]
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

M.debug = require("refactoring.debug")

return M
