vim.cmd "set rtp+=."

vim.cmd "set rtp+=deps/mini.nvim"
vim.cmd "set rtp+=deps/async.nvim"
vim.cmd "set rtp+=deps/mason.nvim"
vim.cmd "set rtp+=deps/nvim-treesitter"

require("mini.test").setup()
require("mason").setup {
  install_root_dir = vim.fn.getcwd() .. "/deps/bin",
}
require("nvim-treesitter").setup {
  install_dir = vim.fn.getcwd() .. "/deps/parsers",
}

vim.lsp.config("lua_ls", {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = {
    ".luarc.json",
    ".luarc.jsonc",
    ".luacheckrc",
    ".stylua.toml",
    "stylua.toml",
    "selene.toml",
    "selene.yml",
    ".git",
  },
})
vim.lsp.config("clangd", {
  cmd = { "clangd" },
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
  root_markers = {
    ".clangd",
    ".clang-tidy",
    ".clang-format",
    "compile_commands.json",
    "compile_flags.txt",
    ".git",
  },
  capabilities = {
    textDocument = {
      completion = {
        editsNearCursor = true,
      },
    },
    offsetEncoding = { "utf-8", "utf-16" },
  },
  on_init = function(client, init_result)
    if init_result.offsetEncoding then client.offset_encoding = init_result.offsetEncoding end
  end,
})
vim.lsp.config("pyright", {
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = {
    ".git",
  },
})
vim.lsp.enable { "lua_ls", "clangd", "pyright" }

vim.g.mapleader = " "
vim.keymap.set("n", "<leader>ai", function()
  return require("refactoring").inline_var()
end, { expr = true })
vim.keymap.set("n", "<leader>ae", function()
  return require("refactoring").extract_func()
end, { expr = true })
vim.keymap.set("n", "<leader>aE", function()
  return require("refactoring").extract_func_to_file()
end, { expr = true })
vim.keymap.set("n", "<leader>av", function()
  return require("refactoring").extract_var()
end, { expr = true })
vim.keymap.set("n", "<leader>aI", function()
  return require("refactoring").inline_func()
end, { expr = true })

vim.keymap.set("n", "<leader>pv", function()
  return require("refactoring.debug").print_var { output_location = "below" }
end, { expr = true })
vim.keymap.set("n", "<leader>pV", function()
  return require("refactoring.debug").print_var { output_location = "above" }
end, { expr = true })

vim.keymap.set({ "x", "n" }, "<leader>pc", function()
  return require("refactoring.debug").cleanup()
end, { expr = true })

vim.keymap.set("n", "<leader>pp", function()
  return require("refactoring.debug").print_loc { output_location = "below" }
end, { expr = true })
vim.keymap.set("n", "<leader>pP", function()
  return require("refactoring.debug").print_loc { output_location = "above" }
end, { expr = true })

vim.keymap.set("n", "<leader>pe", function()
  return require("refactoring.debug").print_exp { output_location = "below" }
end, { desc = "Debug print exp below", expr = true })
vim.keymap.set("n", "<leader>pE", function()
  return require("refactoring.debug").print_exp { output_location = "above" }
end, { desc = "Debug print exp above", expr = true })
