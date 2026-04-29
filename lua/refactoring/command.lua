local M = {}

local api = vim.api
local iter = vim.iter

local DO_NOT_PREVIEW = 0
local PREVIEW_IN_CURRENT_BUFFER = 1

---@param opts vim.api.keyset.create_user_command.command_args
local function command(opts)
  if #opts.fargs == 0 then return end
  local refactor = opts.fargs[1]
  ---@type nil|string[]
  local input = opts.fargs[2] and { opts.fargs[2], opts.fargs[3] }
  local refactor_opts = { input = input }

  if refactor == "inline_var" then vim.cmd.normal(require("refactoring").inline_var(refactor_opts)) end
  if refactor == "extract_var" then vim.cmd.normal("gv" .. require("refactoring").extract_var(refactor_opts)) end
  if refactor == "inline_func" then vim.cmd.normal(require("refactoring").inline_func(refactor_opts)) end
  if refactor == "extract_func" then vim.cmd.normal("gv" .. require("refactoring").extract_func(refactor_opts)) end
  if refactor == "extract_func_to_file" then
    vim.cmd.normal("gv" .. require("refactoring").extract_func_to_file(refactor_opts))
  end
end

local required_input = {
  inline_var = 0,
  extract_var = 1,
  inline_func = 0,
  extract_func = 1,
  extract_func_to_file = 2,
}

-- TODO: cache on preview, use cache always, invalidate cache on CmdlineLeave
---@param opts vim.api.keyset.create_user_command.command_args
---@param ns integer
local function preview(opts, ns)
  if #opts.fargs == 0 then return DO_NOT_PREVIEW end
  local refactor = opts.fargs[1]
  local input = { opts.fargs[2], opts.fargs[3] }

  if not required_input[refactor] or #input < required_input[refactor] then return DO_NOT_PREVIEW end

  local refactor_opts = { input = input, preview_ns = ns }

  -- TODO: `:h command-preview` seems to be broken with async code (it doesn't
  -- show async updates to buffers and may crash Neovim (when modiying buffers
  -- with outdated information?)). Look more into it and open an issue upstream
  if refactor == "inline_var" then vim.cmd.normal(require("refactoring").inline_var(refactor_opts)) end
  if refactor == "extract_var" then vim.cmd.normal("gv" .. require("refactoring").extract_var(refactor_opts)) end
  if refactor == "inline_func" then vim.cmd.normal(require("refactoring").inline_func(refactor_opts)) end
  if refactor == "extract_func" then vim.cmd.normal("gv" .. require("refactoring").extract_func(refactor_opts)) end
  if refactor == "extract_func_to_file" then
    vim.cmd.normal("gv" .. require("refactoring").extract_func_to_file(refactor_opts))
  end

  if
    refactor == "inline_var"
    or refactor == "extract_var"
    or refactor == "inline_func"
    or refactor == "extract_func"
    or refactor == "extract_func_to_file"
  then
    return PREVIEW_IN_CURRENT_BUFFER
  end

  return DO_NOT_PREVIEW
end

---@param arg_lead string
---@param cmd_line string
---@return string[]
local function complete(arg_lead, cmd_line)
  local fargs = vim.split(cmd_line, " ", { trimempty = true })

  if #fargs == 1 or (#fargs == 2 and arg_lead ~= "") then
    return iter({
        "inline_var",
        "extract_var",
        "inline_func",
        "extract_func",
        "extract_func_to_file",
      })
      :filter(
        ---@param item string
        function(item)
          return vim.startswith(item, arg_lead)
        end
      )
      :totable()
  end
  local refactor = fargs[2]
  if
    #fargs == 3 and (refactor == "extract_var" or refactor == "extract_func" or refactor == "extract_func_to_file")
  then
    return {}
  end
  if #fargs == 4 and refactor == "extract_func_to_file" then return vim.fn.getcompletion(arg_lead, "file") end
  return {}
end

function M.setup()
  api.nvim_create_user_command("Refactor", command, {
    nargs = "*",
    range = "%",
    preview = preview,
    complete = complete,
    desc = "Command entrypoint for refactoring.nvim",
    force = true,
  })
end

return M
