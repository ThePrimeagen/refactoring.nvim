### WARNING
There will be some inevitable churn for the next week as I settle on the api!

This is a WORK IN PROGRESS repo :)

#### Things todo
* I want to write tests for a bunch of stuff.
* ...
* stability and profitability

# refactoring.nvim
The Refactoring library based off the Refactoring book by Martin Fowler

## Setup

### Basic
**Packer setup:**
```lua
use {
    "ThePrimeagen/refactoring.nvim",
    requires = {
        {"nvim-lua/plenary.nvim"}
    }
}
```
**Example Config:**
```lua
local refactor = require("refactoring")
refactor.setup()
vim.api.nvim_set_keymap("v", "<Leader>re", [[ <Cmd>lua require('refactoring').refactor('Extract Function')<CR>]], {noremap = true, silent = true, expr = false})
vim.api.nvim_set_keymap("v", "<Leader>rf", [[ <Cmd>lua require('refactoring').refactor('Extract Function To File')<CR>]], {noremap = true, silent = true, expr = false})
```

### Lazyload
**Lazyload with packer Example:**
```lua
use {
    "ThePrimeagen/refactoring.nvim",
    config = require("plugins.refactoring").init,
    opt = true,
    requires = {
        {"nvim-lua/plenary.nvim", opt = true}
    }
}
```
**Lazyload Config:**
```lua
local M = {}

function M.init()
  local refactor = require("refactoring")
  refactor.setup()
end

function M:extract()
  if packer_plugins["refactoring.nvim"] and not packer_plugins["refactoring.nvim"].loaded then
      vim.cmd [[packadd plenary.nvim]]
      vim.cmd [[packadd refactoring.nvim]]
  end

  local refactoring = require("refactoring")
  refactoring.refactor('Extract Function')
end

function M:extract_to_file()
  if packer_plugins["refactoring.nvim"] and not packer_plugins["refactoring.nvim"].loaded then
      vim.cmd [[packadd plenary.nvim]]
      vim.cmd [[packadd refactoring.nvim]]
  end

  local refactoring = require("refactoring")
  refactoring.refactor('Extract Function To File')
end

return M
```
**Lazyload Mappings:**
```lua
vim.api.nvim_set_keymap("v", "<Leader>re", [[ <Cmd>lua require('plugins.refactoring'):extract()<CR>]], {noremap = true, silent = true, expr = false})
vim.api.nvim_set_keymap("v", "<Leader>rf", [[ <Cmd>lua require('plugins.refactoring'):extract_to_file()<CR>]], {noremap = true, silent = true, expr = false})
```
