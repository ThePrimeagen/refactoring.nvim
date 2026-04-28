local M = {}

---@class refactor.debug.Marker
---@field start string
---@field end string

---@private
---@class refactor.debug.Markers
---@field print_var refactor.debug.Marker
---@field print_loc refactor.debug.Marker
---@field print_exp refactor.debug.Marker

---@class refactor.debug.UserMarkers
---@field print_var? refactor.debug.Marker
---@field print_loc? refactor.debug.Marker
---@field print_exp? refactor.debug.Marker

---@private
---@class refactor.debug.cleanup.Opts
---@field types ('print_var'|'print_loc'|'print_exp')[]
---@field restore_view boolean

---@class refactor.debug.cleanup.UserOpts
---@field markers? refactor.debug.UserMarkers
---@field types? ('print_var'|'print_loc'|'print_exp')[]
---@field restore_view? boolean Does not work with dot-repeat

---@private
---@class refactor.debug.print_var.Opts
---@field output_location 'above'|'below'
---@field code_generation refactor.print_var.CodeGeneration

---@class refactor.debug.print_var.UserOpts
---@field marker? refactor.debug.Marker
---@field output_location? 'above'|'below'
---@field code_generation? refactor.print_var.UserCodeGeneration

---@private
---@class refactor.debug.print_loc.Opts
---@field output_location 'above'|'below'
---@field code_generation refactor.print_loc.CodeGeneration

---@class refactor.debug.print_loc.UserOpts
---@field marker? refactor.debug.Marker
---@field output_location? 'above'|'below'
---@field code_generation? refactor.print_loc.UserCodeGeneration

---@private
---@class refactor.debug.print_exp.Opts
---@field output_location 'above'|'below'
---@field code_generation refactor.print_exp.CodeGeneration

---@class refactor.debug.print_exp.UserOpts
---@field marker? refactor.debug.Marker
---@field output_location? 'above'|'below'
---@field code_generation? refactor.print_exp.CodeGeneration

---@alias refactor.DebugFunc fun(type: 'v' | 'V' | '', opts: refactor.Config|nil)

local last_debug ---@type refactor.DebugFunc|nil
local last_config ---@type refactor.Config|nil

---@private
---@param type "line" | "char" | "block"
function M.debug_operatorfunc(type)
  if not last_debug then return end

  local range_type = type == "line" and "V" or type == "char" and "v" or ""
  last_debug(range_type, last_config)
end

--- Inserts a debug print statement with all the variable and locations
--- (e.g. `some_function#if#for`) in the selected range.
--- - Requires:
---   - Tree-sitter parser and queries (`refactor_comment`,
---   `refactor_reference`, `refactor_output_statement` and `refactor_scope`)
---@param opts refactor.debug.print_var.UserOpts?
function M.print_var(opts)
  local config = require("refactoring.config").get_config(0, {
    debug = {
      markers = opts and { print_var = opts.marker },
      print_var = opts,
    },
  })

  vim.o.operatorfunc = "v:lua.require'refactoring.debug'.debug_operatorfunc"
  last_debug = require("refactoring.debug.print_var").print_var
  last_config = config
  return "g@"
end

M._last_view = nil ---@type vim.fn.winsaveview.ret|nil

--- Cleanup the debug print statements in the selected range.
--- - Requires:
---   - Tree-sitter parser and queries (`refactor_comment`)
---@param opts refactor.debug.cleanup.UserOpts?
function M.cleanup(opts)
  local config = require("refactoring.config").get_config(0, {
    debug = {
      markers = opts and opts.markers,
      cleanup = opts,
    },
  })

  vim.o.operatorfunc = "v:lua.require'refactoring.debug'.debug_operatorfunc"
  last_debug = require("refactoring.debug.cleanup").cleanup
  last_config = config
  if config.debug.cleanup.restore_view then M._last_view = vim.fn.winsaveview() end
  return "g@"
end

--- Inserts a debug print statement with the location under cursor (e.g.
--- `some_function#if#for`).
--- - Requires:
---   - Tree-sitter parser and queries (`refactor_comment` and
---   `refactor_output_statement`)
---@param opts refactor.debug.print_loc.UserOpts?
function M.print_loc(opts)
  local config = require("refactoring.config").get_config(0, {
    debug = {
      markers = opts and { print_loc = opts.marker },
      print_loc = opts,
    },
  })

  vim.o.operatorfunc = "v:lua.require'refactoring.debug'.debug_operatorfunc"
  last_debug = require("refactoring.debug.print_loc").print_loc
  last_config = config
  return "g@l"
end

--- Inserts a debug print statement with the selected expression and location
--- (e.g. `some_function#if#for`).
--- - Requires:
---   - Tree-sitter parser and queries (`refactor_comment` and
---   `refactor_output_statement`)
---@param opts refactor.debug.print_exp.UserOpts?
function M.print_exp(opts)
  local config = require("refactoring.config").get_config(0, {
    debug = {
      markers = opts and { print_exp = opts.marker },
      print_exp = opts,
    },
  })

  vim.o.operatorfunc = "v:lua.require'refactoring.debug'.debug_operatorfunc"
  last_debug = require("refactoring.debug.print_exp").print_exp
  last_config = config
  return "g@"
end

return M
