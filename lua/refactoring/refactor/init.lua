local extract = require("refactoring.refactor.106")
local extract_var = require("refactoring.refactor.119")
local inline_var = require("refactoring.refactor.123")

local M = {}

-- TODO: Better Way?
-- First thought is to make extract a function that adds its functions to the M
-- object... not sure if I like that.
M.extract = extract.extract
M.extract_to_file = extract.extract_to_file
M.extract_var = extract_var.extract_var
M.inline_var = inline_var.inline_var

-- TODO: Perhaps I am really out thinking myself on this one.  But it seems way
-- nicer if we can query all the names of refactors that allow us to use fzf or
-- telescope for nice intergration with refactor picking
M.refactor_names = {
    ["Inline Variable"] = "inline_var",
    ["Extract Variable"] = "extract_var",
    ["Extract Function"] = "extract",
    ["Extract Function To File"] = "extract_to_file",
}

return M
