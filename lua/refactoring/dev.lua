local ts_utils = require("nvim-treesitter.ts_utils")
local Query = require("refactoring.query")
local Region = require("refactoring.region")

local M = {}
M.reload = function()
    require("plenary.reload").reload_module("refactoring")
end

function M.debug_current_selection()
    local bufnr = vim.fn.bufnr()
    local filetype = vim.bo[bufnr].filetype
    local query = Query:new(
        bufnr,
        filetype,
        vim.treesitter.get_query(filetype, "refactoring")
    )
    if query == nil then
        error("Unable to get query information for filetype")
    end

    local region = Region:from_current_selection()
    print("Debugging for", bufnr)
    print("Region", vim.inspect(region))
    print(
        "Selection:Scope",
        vim.inspect(ts_utils.get_node_text(query:get_scope_over_region(region)))
    )
end

function M.print_selections_sexpr()
    local bufnr = vim.fn.bufnr()
    local filetype = vim.bo[bufnr].filetype
    local root = Query.get_root(bufnr, filetype)
    local region = Region:from_current_selection()
    local selection_node = root:named_descendant_for_range(region:to_ts())
    print(vim.inspect(selection_node:sexpr()))
end

return M
