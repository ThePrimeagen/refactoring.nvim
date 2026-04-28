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

T["lua"]["works"] = function()
  local lines = read_file "./tests/files/extract_func_works_before.lua"
  local expected_lines = read_file "./tests/files/extract_func_works_after.lua"
  child.cmd "edit tmp.lua"
  validate(lines, { 15, 0 }, expected_lines, " aeip", "bar<cr>")
end

T["lua"]["defaults to extracted location"] = function()
  local lines = read_file "./tests/files/extract_func_defaults_to_selected_location_before.lua"
  local expected_lines = read_file "./tests/files/extract_func_defaults_to_selected_location_after.lua"
  child.cmd "edit tmp.lua"
  validate(lines, { 1, 0 }, expected_lines, " aeip", "bar<cr>")
end

T["lua"]["identifies references outside extracted range scope"] = function()
  local lines = read_file "./tests/files/extract_func_identifies_references_outside_selected_range_scope_before.lua"
  local expected_lines =
    read_file "./tests/files/extract_func_identifies_references_outside_selected_range_scope_after.lua"
  child.cmd "edit tmp.lua"
  validate(lines, { 1, 0 }, expected_lines, " ae_", "foo2<cr>")
end

T["lua"]["chooses correct declaration"] = function()
  local lines = read_file "./tests/files/extract_func_chooses_correct_declaration_before.lua"
  local expected_lines = read_file "./tests/files/extract_func_chooses_correct_declaration_after.lua"
  child.cmd "edit tmp.lua"
  validate(lines, { 1, 0 }, expected_lines, " ae_", "foo2<cr>")
end

T["lua"]["to new file"] = function()
  local input_lines = read_file "./tests/files/extract_func_to_new_file_before.lua"
  local expected_input_lines = read_file "./tests/files/extract_func_to_new_file_after.lua"
  local new_file = "new.lua"
  child.cmd "edit tmp.lua"
  validate(input_lines, { 1, 0 }, expected_input_lines, " aE_", ("%s<cr>"):format(new_file), "foo<cr>")

  local expected_output_lines = read_file "./tests/files/extract_func_new_file.lua"
  child.cmd(("edit %s"):format(new_file))
  eq(get_lines(), vim.split(expected_output_lines, "\n"))
end

T["lua"]["to existing file"] = function()
  local input_lines = read_file "./tests/files/extract_func_to_existing_file_before.lua"
  local expected_input_lines = read_file "./tests/files/extract_func_to_existing_file_after.lua"
  local existing_file = "existing.lua"
  child.cmd(("edit %s"):format(existing_file))

  local output_lines = read_file "./tests/files/extract_func_existing_file_before.lua"
  set_lines(output_lines)

  child.cmd "edit tmp.lua"
  validate(input_lines, { 1, 0 }, expected_input_lines, " aE_", ("%s<cr>"):format(existing_file), "foo<cr>")

  local expected_output_lines = read_file "./tests/files/extract_func_existing_file_after.lua"
  child.cmd(("edit %s"):format(existing_file))
  eq(get_lines(), vim.split(expected_output_lines, "\n"))
end

T["java"] = MiniTest.new_set {
  hooks = {
    pre_case = function()
      child.lua [[
vim.api.nvim_create_autocmd('Filetype', {
  pattern = 'java',
  command = 'setlocal expandtab shiftwidth=4'
})
]]
    end,
  },
}

T["java"]["works"] = function()
  local lines = read_file "./tests/files/extract_func_works_before.java"
  local expected_lines = read_file "./tests/files/extract_func_works_after.java"
  child.cmd "edit tmp.java"
  validate(lines, { 22, 0 }, expected_lines, " aeip", "bar<cr>")
end

T["php"] = MiniTest.new_set {
  hooks = {
    pre_case = function()
      child.lua [[
vim.api.nvim_create_autocmd('Filetype', {
  pattern = 'php',
  command = 'setlocal expandtab shiftwidth=4'
})
]]
    end,
  },
}

T["php"]["works"] = function()
  local lines = read_file "./tests/files/extract_func_works_before.php"
  local expected_lines = read_file "./tests/files/extract_func_works_after.php"
  child.cmd "edit tmp.php"
  validate(lines, { 21, 0 }, expected_lines, " aeip", "bar<cr>")
end

T["go"] = MiniTest.new_set {
  hooks = {
    pre_case = function()
      child.lua [[
vim.api.nvim_create_autocmd('Filetype', {
  pattern = 'go',
  command = 'setlocal noexpandtab'
})
]]
    end,
  },
}

T["go"]["works"] = function()
  local lines = read_file "./tests/files/extract_func_works_before.go"
  local expected_lines = read_file "./tests/files/extract_func_works_after.go"
  child.cmd "edit tmp.go"
  validate(lines, { 21, 0 }, expected_lines, " aeip", "bar<cr>")
end

T["go"]["method"] = function()
  local lines = read_file "./tests/files/extract_func_method_before.go"
  local expected_lines = read_file "./tests/files/extract_func_method_after.go"
  child.cmd "edit tmp.go"
  validate(lines, { 8, 0 }, expected_lines, " ae_", "foo<cr>")
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
  local lines = read_file "./tests/files/extract_func_works_before.ps1"
  local expected_lines = read_file "./tests/files/extract_func_works_after.ps1"
  child.cmd "edit tmp.ps1"
  validate(lines, { 21, 0 }, expected_lines, " aeip", "bar<cr>")
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
  local lines = read_file "./tests/files/extract_func_works_before.py"
  local expected_lines = read_file "./tests/files/extract_func_works_after.py"
  child.cmd "edit tmp.py"
  validate(lines, { 18, 8 }, expected_lines, " aeip", "bar<cr>")
end

T["ruby"] = MiniTest.new_set {
  hooks = {
    pre_case = function()
      child.lua [[
vim.api.nvim_create_autocmd('Filetype', {
  pattern = 'ruby',
  command = 'setlocal expandtab shiftwidth=2'
})
]]
    end,
  },
}

T["ruby"]["works"] = function()
  local lines = read_file "./tests/files/extract_func_works_before.rb"
  local expected_lines = read_file "./tests/files/extract_func_works_after.rb"
  child.cmd "edit tmp.rb"
  validate(lines, { 19, 4 }, expected_lines, " aeip", "bar<cr>")
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
  local lines = read_file "./tests/files/extract_func_works_before.vim"
  local expected_lines = read_file "./tests/files/extract_func_works_after.vim"
  child.cmd "edit tmp.vim"
  validate(lines, { 16, 8 }, expected_lines, " aeip", "bar<cr>")
end

return T
