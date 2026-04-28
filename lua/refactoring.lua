--- *refactoring.nvim* Refactor and print debugging

--- Features:
--- - Inline variable:
---   - Inline the definition of the variable under cursor into all its references.
---   - Requires:
---     - LSP server with support for `textDocument/references` and `textDocument/definition`
---     - Tree-sitter parser and queries (`refactor_reference` and `refactor_variable`)
--- - Extract variable:
---   - Extract an expression, and all its usages in a buffer, into a variable.
---   - Requires:
---     - Tree-sitter parser and queries (`refactor_scope` and `refactor_output_statement`)
--- - Inline function:
---   - Inline the definition of the function under cursor into all its
---   references (only supports functions with a single return statement).
---   - Requires:
---     - LSP server with support for `textDocument/references` and `textDocument/definition`
---     - Tree-sitter parser and queries (`refactor_function` and `refactor_function_call`)
--- - Extract function:
---   - Extract text into a function and replace it with a call to that function.
---   - Requires:
---     - Tree-sitter parser and queries (`refactor_reference`, `refactor_scope`,
---     `refactor_output_function` and `refactor_input_function`)
--- - Print location:
---   - Inserts a debug print statement with the location under cursor (e.g. `some_function#if#for`).
---   - Requires:
---     - Tree-sitter parser and queries (`refactor_comment` and `refactor_output_statement`)
--- - Print variable:
---   - Inserts a debug print statement with all the variable and locations
---   (e.g. `some_function#if#for`) in the selected range.
---   - Requires:
---     - Tree-sitter parser and queries (`refactor_comment`,
---     `refactor_reference`, `refactor_output_statement` and `refactor_scope`)
--- - Print expression:
---   - Inserts a debug print statement with the selected expression and
---   location (e.g. `some_function#if#for`).
---   - Requires:
---     - Tree-sitter parser and queries (`refactor_comment` and `refactor_output_statement`)
--- - Debug print cleanup:
---   - Cleanup the debug print statements in the selected range.
---   - Requires:
---     - Tree-sitter parser and queries (`refactor_comment`)
---@tag refactoring

local async = require "async"
local api = vim.api

local M = {}

---@private
---@class refactor.refactor.extract_func.Opts
---@field input string[]?
---@field preview_ns integer?
---@field code_generation refactor.extract_func.CodeGeneration

---@class refactor.refactor.extract_func.UserOpts
---@field show_success_message boolean?
---@field input string[]?
---@field preview_ns integer?
---@field code_generation? refactor.extract_func.UserCodeGeneration

---@private
---@class refactor.refactor.extract_var.Opts
---@field input string[]?
---@field preview_ns integer?
---@field code_generation refactor.extract_var.CodeGeneration

---@class refactor.refactor.extract_var.UserOpts
---@field show_success_message boolean?
---@field input string[]?
---@field preview_ns integer?
---@field code_generation? refactor.extract_var.UserCodeGeneration

---@private
---@class refactor.refactor.inline_var.Opts
---@field input string[]?
---@field preview_ns integer?
---@field code_generation refactor.inline_var.CodeGeneration

---@class refactor.refactor.inline_var.UserOpts
---@field show_success_message boolean?
---@field input string[]?
---@field preview_ns integer?
---@field code_generation? refactor.inline_var.UserCodeGeneration

---@private
---@class refactor.refactor.inline_func.Opts
---@field input string[]?
---@field preview_ns integer?
---@field code_generation refactor.inline_func.CodeGeneration

---@class refactor.refactor.inline_func.UserOpts
---@field show_success_message boolean?
---@field input string[]?
---@field preview_ns integer?
---@field code_generation? refactor.inline_func.UserCodeGeneration

---@alias refactor.RefactorFunc fun(type: 'v' | 'V' | '', opts: refactor.Config|nil)

local last_refactor ---@type refactor.RefactorFunc|nil
local last_config ---@type refactor.Config|nil

---@private
---@param type "line" | "char" | "block"
function M.refactor_operatorfunc(type)
  if not last_refactor then return end

  local range_type = type == "line" and "V" or type == "char" and "v" or ""
  last_refactor(range_type, last_config)
end

--- Extract text into a function and replace it with a call to that function.
---
--- - Requires:
---   - Tree-sitter parser and queries (`refactor_reference`, `refactor_scope`,
---   `refactor_output_function` and `refactor_input_function`)
---@param opts refactor.refactor.extract_func.UserOpts?
function M.extract_func(opts)
  local config = require("refactoring.config").get_config(0, {
    show_success_message = opts and opts.show_success_message,
    refactor = {
      extract_func = opts,
    },
  })

  vim.o.operatorfunc = "v:lua.require'refactoring'.refactor_operatorfunc"
  last_refactor = require("refactoring.refactor.extract_func").extract_func
  last_config = config
  return "g@"
end

--- Extract text into a function in a different file and replace it with a call
--- to that function.
---
--- - Requires:
---   - Tree-sitter parser and queries (`refactor_reference`, `refactor_scope`,
---   `refactor_output_function` and `refactor_input_function`)
---@param opts refactor.refactor.extract_func.UserOpts?
function M.extract_func_to_file(opts)
  local config = require("refactoring.config").get_config(0, {
    show_success_message = opts and opts.show_success_message,
    refactor = {
      extract_func = opts,
    },
  })

  vim.o.operatorfunc = "v:lua.require'refactoring'.refactor_operatorfunc"
  last_refactor = require("refactoring.refactor.extract_func").extract_func_to_file
  last_config = config
  return "g@"
end

--- Extract an expression, and all its usages in a buffer, into a variable.
---
--- - Requires:
---   - Tree-sitter parser and queries (`refactor_scope` and
---   `refactor_output_statement`)
---@param opts refactor.refactor.extract_var.UserOpts?
function M.extract_var(opts)
  local config = require("refactoring.config").get_config(0, {
    show_success_message = opts and opts.show_success_message,
    refactor = {
      extract_var = opts,
    },
  })

  vim.o.operatorfunc = "v:lua.require'refactoring'.refactor_operatorfunc"
  last_refactor = require("refactoring.refactor.extract_var").extract_var
  last_config = config
  return "g@"
end

--- Inline the definition of the variable under cursor into all its references.
---
--- - Requires:
---   - LSP server with support for `textDocument/references` and `textDocument/definition`
---   - Tree-sitter parser and queries (`refactor_reference` and `refactor_variable`)
---@param opts refactor.refactor.inline_var.UserOpts?
function M.inline_var(opts)
  local config = require("refactoring.config").get_config(0, {
    show_success_message = opts and opts.show_success_message,
    refactor = {
      inline_var = opts,
    },
  })

  vim.o.operatorfunc = "v:lua.require'refactoring'.refactor_operatorfunc"
  last_refactor = require("refactoring.refactor.inline_var").inline_var
  last_config = config
  return "g@l"
end

--- Inline the definition of the function under cursor into all its
--- references (only supports functions with a single return statement).
--- - Requires:
---   - LSP server with support for `textDocument/references` and
---   `textDocument/definition`
---   - Tree-sitter parser and queries (`refactor_function` and
---   `refactor_function_call`)
---@param opts refactor.refactor.inline_func.UserOpts?
function M.inline_func(opts)
  local config = require("refactoring.config").get_config(0, {
    show_success_message = opts and opts.show_success_message,
    refactor = {
      inline_func = opts,
    },
  })

  vim.o.operatorfunc = "v:lua.require'refactoring'.refactor_operatorfunc"
  last_refactor = require("refactoring.refactor.inline_func").inline_func
  last_config = config
  return "g@l"
end

---@class refactor.select_refactor.Opts
---@field prefer_ex_cmd boolean?

--- Use |vim.ui.select()| to select a refactor.
---
--- The `prefer_ex_cmd` option can be used to pre-populate the command line
--- with the ex command needed to execute the refactor. This allows to previews
--- changes.
---@param opts? refactor.select_refactor.Opts
function M.select_refactor(opts)
  local prefer_ex_cmd = opts and opts.prefer_ex_cmd or false

  local mode = api.nvim_get_mode().mode

  local task = async.run(function()
    local select = require("refactoring.utils").select
    ---@type nil|{name: string, command: string, fn: fun(): string}
    local selected = select({
      { name = "Inline variable", fn = M.inline_var, command = "inline_var" },
      { name = "Extract variable", fn = M.extract_var, command = "extract_var" },
      { name = "Inline function", fn = M.inline_func, command = "inline_func" },
      { name = "Extract function", fn = M.extract_func, command = "extract_func" },
    }, {
      prompt = "Select a refactor:",
      format_item = function(item)
        return item.name
      end,
    })
    if not selected then return end

    if prefer_ex_cmd then
      api.nvim_input((":Refactor %s "):format(selected.command))
      return
    end

    local keys = selected.fn()
    if (mode == "v" or mode == "V" or mode == "\22") and keys == "g@" then keys = "gvg@" end
    api.nvim_input(keys)
  end)
  task:raise_on_error()
end

--- Change the default configuration of `refactoring.nvim`.
---
--- NOTE: there is no need to call this function if you are happy with the
--- defaults.
---@param opts? refactor.UserConfig
function M.setup(opts)
  require("refactoring.config").setup(opts)
end

return M
