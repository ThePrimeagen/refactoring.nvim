---@module "mini.test"

local child = MiniTest.new_child_neovim()

local expect, eq = MiniTest.expect, MiniTest.expect.equality

---@type {[string]: any|{[string]: any}}
local T = MiniTest.new_set {
  hooks = {
    pre_case = function()
      child.restart { "-u", "scripts/minimal_init.lua" }
      child.bo.readonly = false
      -- NOTE: we use `vim.notify` to show warnings to users, this makes
      -- it easier to catch them with mini.test
      child.lua "vim.notify = function(msg, level) if level == vim.log.levels.ERROR then error(msg) end end"
    end,
    post_once = child.stop,
  },
}

---@param lines string
local set_lines = function(lines)
  child.api.nvim_buf_set_lines(0, 0, -1, true, vim.split(lines, "\n"))
end

local get_lines = function()
  return child.api.nvim_buf_get_lines(0, 0, -1, true)
end

---@param row integer
---@param col integer
local set_cursor = function(row, col)
  child.api.nvim_win_set_cursor(0, { row, col })
end

---@param lines string
---@param cursor {[1]: integer, [2]: integer}
---@param expected_lines string
---@param ... string
local function validate(lines, cursor, expected_lines, ...)
  set_lines(lines)
  set_cursor(cursor[1], cursor[2])
  child.type_keys(...)
  eq(get_lines(), vim.split(expected_lines, "\n"))
end

---@param path string
---@return string
local function read_file(path)
  local file = io.open(path)
  assert(file)
  local lines = file:read "*a"
  -- NOTE: remove trailling newline to avoid issues when splitting by newlines
  lines = lines:gsub("\n$", "") ---@type string

  return lines
end

T["lua"] = MiniTest.new_set {
  hooks = {
    pre_case = function()
      child.lua [[
vim.api.nvim_create_autocmd('Filetype', {
  pattern = 'lua',
  command = 'setlocal expandtab shiftwidth=2'
})
]]
    end,
  },
}

T["lua"]["works below"] = function()
  local lines = read_file "./tests/files/print_var_works_below_before.lua"
  local expected_lines = read_file "./tests/files/print_var_works_below_after.lua"
  child.cmd "edit tmp.lua"
  validate(lines, { 1, 0 }, expected_lines, " pvG")
end

T["lua"]["works above"] = function()
  local lines = read_file "./tests/files/print_var_works_above_before.lua"
  local expected_lines = read_file "./tests/files/print_var_works_above_after.lua"
  child.cmd "edit tmp.lua"
  validate(lines, { 3, 0 }, expected_lines, " pVG")
end

T["c"] = MiniTest.new_set {
  hooks = {
    pre_case = function()
      child.lua [[
vim.api.nvim_create_autocmd('Filetype', {
  pattern = 'c',
  command = 'setlocal expandtab shiftwidth=2'
})
]]
    end,
  },
}

T["c"]["works"] = function()
  local lines = read_file "./tests/files/print_var_works_before.c"
  local expected_lines = read_file "./tests/files/print_var_works_after.c"
  child.cmd "edit tmp.c"
  validate(lines, { 4, 6 }, expected_lines, " pviw")
end

T["javascript"] = MiniTest.new_set {
  hooks = {
    pre_case = function()
      child.lua [[
vim.api.nvim_create_autocmd('Filetype', {
  pattern = 'javascript',
  command = 'setlocal expandtab shiftwidth=2'
})
]]
    end,
  },
}

T["javascript"]["works"] = function()
  local lines = read_file "./tests/files/print_var_works_before.js"
  local expected_lines = read_file "./tests/files/print_var_works_after.js"
  child.cmd "edit tmp.js"
  validate(lines, { 2, 8 }, expected_lines, " pviw")
end

T["powershell"] = MiniTest.new_set {
  hooks = {
    pre_case = function()
      child.lua [[
vim.api.nvim_create_autocmd('Filetype', {
  pattern = 'ps1',
  command = 'setlocal expandtab shiftwidth=4'
})
]]
    end,
  },
}

T["powershell"]["works"] = function()
  local lines = read_file "./tests/files/print_var_works_before.ps1"
  local expected_lines = read_file "./tests/files/print_var_works_after.ps1"
  child.cmd "edit tmp.ps1"
  validate(lines, { 2, 4 }, expected_lines, " pviW")
end

T["python"] = MiniTest.new_set {
  hooks = {
    pre_case = function()
      child.lua [[
vim.api.nvim_create_autocmd('Filetype', {
  pattern = 'python',
  command = 'setlocal expandtab shiftwidth=4'
})
]]
    end,
  },
}

T["python"]["works"] = function()
  local lines = read_file "./tests/files/print_var_works_before.py"
  local expected_lines = read_file "./tests/files/print_var_works_after.py"
  child.cmd "edit tmp.py"
  validate(lines, { 2, 0 }, expected_lines, " pv_")
end

T["vimscript"] = MiniTest.new_set {
  hooks = {
    pre_case = function()
      child.lua [[
vim.api.nvim_create_autocmd('Filetype', {
  pattern = 'vim',
  command = 'setlocal expandtab shiftwidth=4'
})
]]
    end,
  },
}

T["vimscript"]["works"] = function()
  local lines = read_file "./tests/files/print_var_works_before.vim"
  local expected_lines = read_file "./tests/files/print_var_works_after.vim"
  child.cmd "edit tmp.vim"
  validate(lines, { 2, 8 }, expected_lines, " pviw")
end

return T
