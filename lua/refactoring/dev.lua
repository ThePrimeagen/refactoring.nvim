local ts_utils = require("nvim-treesitter.ts_utils")
local Query = require("refactoring.query")
local TreeSitter = require("refactoring.treesitter")
local Region = require("refactoring.region")
local Point = require("refactoring.point")

local M = {}
M.reload = function()
    require("plenary.reload").reload_module("refactoring")
end

function M.create_query_from_buffer()
    local bufnr = vim.fn.bufnr()
    local filetype = vim.bo[bufnr].filetype
    return Query:new(
        bufnr,
        filetype,
        vim.treesitter.get_query(filetype, "refactoring")
    )
end

function M.get_scope_from_cursor()
    local query = M.create_query_from_buffer()
    if query == nil then
        error("Unable to get query information for filetype")
    end

    return query:get_scope_by_position(vim.fn.line("."), vim.fn.col("."))
end

function M.get_scope_from_region(region)
    local query = M.create_query_from_buffer()
    if query == nil then
        error("Unable to get query information for filetype")
    end

    return query:get_scope_over_region(region)
end

function M.debug_current_selection()
    local bufnr = vim.fn.bufnr()
    local region = Region:from_current_selection()
    local scope = M.get_scope_from_region(region)

    print("Debugging for", bufnr)
    print("Region", vim.inspect(region))
    print("Selection:Scope", vim.inspect(ts_utils.get_node_text(scope)))
end

function M.print_selections_sexpr()
    local bufnr = vim.fn.bufnr()
    local filetype = vim.bo[bufnr].filetype
    local root = Query.get_root(bufnr, filetype)
    local region = Region:from_current_selection()
    local selection_node = root:named_descendant_for_range(region:to_ts())
    print(vim.inspect(selection_node:sexpr()))
end

function M.print_local_def()
    local def = TreeSitter.get_treesitter():local_declarations_under_cursor()

    print(def)
    print(vim.inspect(def))
    print(def[1]:type())
    print(ts_utils.get_node_text(def))
end

function M.get_current_node()
    local root = TreeSitter.get_treesitter():get_root()
    return Point:from_cursor():to_ts_node(root)
end

function M.print_scope(scope)
    print(vim.inspect(ts_utils.get_node_text(scope)))
end

return M
