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
**Packer setup:**
```lua
use {
    "ThePrimeagen/refactoring.nvim",
    require = {
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
