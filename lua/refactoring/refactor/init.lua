local extract = require("refactoring.refactor.106")
local inline_func = require("refactoring.refactor.115")
local extract_var = require("refactoring.refactor.119")
local inline_var = require("refactoring.refactor.123")

---@type table<string|integer,function>|table<string, table<string, string>>
local M = {}

M.extract = extract.extract
M.extract_to_file = extract.extract_to_file
M.extract_block = extract.extract_block
M.extract_block_to_file = extract.extract_block_to_file
M.inline_func = inline_func.inline_func
M.extract_var = extract_var.extract_var
M.inline_var = inline_var.inline_var

M[106] = extract.extract
M[115] = inline_func.inline_func
M[119] = extract_var.extract_var
M[123] = inline_var.inline_var

M.refactor_names = {
    ["Inline Variable"] = "inline_var",
    ["Extract Variable"] = "extract_var",
    ["Extract Function"] = "extract",
    ["Extract Function To File"] = "extract_to_file",
    ["Extract Block"] = "extract_block",
    ["Extract Block To File"] = "extract_block_to_file",
    ["Inline Function"] = "inline_func",
}

return M
