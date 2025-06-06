<div align="center">

  <h1>refactoring.nvim</h1>
  <h5>The Refactoring library based off the Refactoring book by Martin Fowler</h5>
  <h6>'If I use an environment that has good automated refactorings, I can trust those refactorings' - Martin Fowler</h6>

[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)
[![Neovim 0.10](https://img.shields.io/badge/Neovim%200.10-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io)
![Work In Progress](https://img.shields.io/badge/Work%20In%20Progress-orange?style=for-the-badge)

</div>

## Table of Contents

- [Installation](#installation)
  - [Requirements](#requirements)
  - [Setup Using Packer](#packer)
  - [Setup Using Lazy](#lazy)
  - [Quickstart](#quickstart)
- [Features](#features)
  - [Supported Languages](#supported-languages)
  - [Refactoring Features](#refactoring-features)
  - [Debug Features](#debug-features)
- [Configuration](#configuration)
  - [Configuration for Refactoring Operations](#config-refactoring)
    - [Ex Commands](#config-refactoring-command)
    - [Lua API](#config-refactoring-direct)
    - [Using Built-In Neovim Selection](#config-refactoring-builtin)
    - [Using Telescope](#config-refactoring-telescope)
  - [Configuration for Debug Operations](#config-debug)
    - [Customizing Printf and Print Var Statements](#config-debug-stringification)
      - [Customizing Printf Statements](#config-debug-stringification-printf)
      - [Customizing Print Var Statements](#config-debug-stringification-print-var)
  - [Customizing Extract Variable Statements](#config-119-custom)
  - [Configuration for Type Prompt Operations](#config-prompt)

## Installation<a name="installation"></a>

### Requirements<a name="requirements"></a>

- **Neovim 0.10**
- Treesitter
- Plenary

### Setup Using Packer<a name="packer"></a>

```lua
use {
    "ThePrimeagen/refactoring.nvim",
    requires = {
        {"nvim-lua/plenary.nvim"},
        {"nvim-treesitter/nvim-treesitter"}
    }
}
```

### Setup Using Lazy<a name="lazy"></a>

```lua
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    lazy = false,
    opts = {},
  },
```

### Quickstart<a name="quickstart"></a>

```lua
require('refactoring').setup()
```

## Features<a name="features"></a>

### Supported Languages<a name="supported-languages"></a>

Given that this is a work in progress, the languages supported for the
operations listed below is **constantly changing**. As of now, these languages
are supported (with individual support for each function may vary):

- TypeScript
- JavaScript
- Lua
- C/C++
- Golang
- Python
- Java
- PHP
- Ruby
- C#

### Refactoring Features<a name="refactoring-features"></a>

- Support for various common refactoring operations
  - **106: Extract Function**
    - Extracts the last highlighted code from visual mode to a separate function
    - Optionally prompts for function param types and return types (see
      [configuration for type prompt operations](#config-prompt))
    - Also possible to Extract Block.
    - Both Extract Function and Extract Block have the capability to extract to
      a separate file.
  - **115: Inline Function**
    - Inverse of extract function
    - In normal mode, inline occurrences of the function under the cursor
    - The function under the cursor has to be the declaration of the function
  - **119: Extract Variable**
    - In visual mode, extracts occurrences of a selected expression to its own
      variable, replacing occurrences of that expression with the variable
  - **123: Inline Variable**
    - Inverse of extract variable
    - Replaces all occurrences of a variable with its value
    - Can be used in normal mode or visual mode
      - Using this function in normal mode will automatically find the variable
        under the cursor and inline it
      - Using this function in visual mode will find the variable(s) in the
        visual selection.
        - If there is more than one variable in the selection, the plugin will
          prompt for which variable to inline,
        - If there is only one variable in the visual selection, it will
          automatically inline that variable

### Debug Features<a name="debug-features"></a>

- Also comes with various useful features for debugging
  - **Printf:** Automated insertion of print statement to mark the calling of a
    function
    - dot-repeatable
  - **Print var:** Automated insertion of print statement to print a variable
    at a given point in the code. This map can be made with either visual or
    normal mode:
    - Using this function in visual mode will print out whatever is in the
      visual selection.
    - Using this function in normal mode will print out the identifier
      under the cursor
    - dot-repeatable
  - **Cleanup:** Automated cleanup of all print statements generated by the
    plugin

## Configuration<a name="configuration"></a>

There are many ways to configure this plugin. Below are some example configurations.

**Setup Function**

No matter which configuration option you use, you must first call the
setup function.

```lua
require('refactoring').setup({})
```

Here are all the available options for the setup function and their defaults:

```lua
require('refactoring').setup({
    prompt_func_return_type = {
        go = false,
        java = false,

        cpp = false,
        c = false,
        h = false,
        hpp = false,
        cxx = false,
    },
    prompt_func_param_type = {
        go = false,
        java = false,

        cpp = false,
        c = false,
        h = false,
        hpp = false,
        cxx = false,
    },
    printf_statements = {},
    print_var_statements = {},
    show_success_message = false, -- shows a message with information about the refactor on success
                                  -- i.e. [Refactor] Inlined 3 variable occurrences
})
```

See each of the sections below for details on each configuration option.

### Configuration for Refactoring Operations<a name="config-refactoring"></a>

#### Ex Commands <a name="config-refactoring-command"></a>

The plugin offers the `:Refactor` command as an alternative to the Lua API.

The first argument to the command selects the type of refactor to perform.
Additional arguments will be passed to each refactor if needed (e.g. the name
of the extracted function for `extract`).

The first argument can be tab completed, so there is no need to memorize them all.
(e.g. `:Refactor e<tab>` will suggest `extract_block_to_file`, `extract`, `extract_block`,
`extract_var` and `extract_to_file`).

The main advantage of using an Ex command instead of the Lua API is that you
will be able to preview the changes made by the refactor before committing to
them.

https://github.com/ThePrimeagen/refactoring.nvim/assets/53507599/6ad58376-c503-4504-ab07-3590ae9a6c75

The command can also be used in mappings:

```lua
vim.keymap.set("x", "<leader>re", ":Refactor extract ")
vim.keymap.set("x", "<leader>rf", ":Refactor extract_to_file ")

vim.keymap.set("x", "<leader>rv", ":Refactor extract_var ")

vim.keymap.set({ "n", "x" }, "<leader>ri", ":Refactor inline_var")

vim.keymap.set( "n", "<leader>rI", ":Refactor inline_func")

vim.keymap.set("n", "<leader>rb", ":Refactor extract_block")
vim.keymap.set("n", "<leader>rbf", ":Refactor extract_block_to_file")

```

The ` ` (space) at the end of some mappings is intentional because those
mappings expect an additional argument (all of these mappings leave the user in
command mode to utilize the preview command feature).

#### Lua API <a name="config-refactoring-direct"></a>

If you want to make remaps for a specific refactoring operation, you can do so
by configuring the plugin like this:

```lua
vim.keymap.set({ "n", "x" }, "<leader>re", function() return require('refactoring').refactor('Extract Function') end, { expr = true })
vim.keymap.set({ "n", "x" }, "<leader>rf", function() return require('refactoring').refactor('Extract Function To File') end, { expr = true })
vim.keymap.set({ "n", "x" }, "<leader>rv", function() return require('refactoring').refactor('Extract Variable') end, { expr = true })
vim.keymap.set({ "n", "x" }, "<leader>rI", function() return require('refactoring').refactor('Inline Function') end, { expr = true })
vim.keymap.set({ "n", "x" }, "<leader>ri", function() return require('refactoring').refactor('Inline Variable') end, { expr = true })

vim.keymap.set({ "n", "x" }, "<leader>rbb", function() return require('refactoring').refactor('Extract Block') end, { expr = true })
vim.keymap.set({ "n", "x" }, "<leader>rbf", function() return require('refactoring').refactor('Extract Block To File') end, { expr = true })
```

IMPORTANT: the keymaps **MUST** to be created using the `{ expr = true }` option and return the value of the `require('refactoring').refactor` function (like in the example above).

#### Using Built-In Neovim Selection<a name="config-refactoring-builtin"></a>

You can also set up the plugin to prompt for a refactoring operation to apply
using Neovim's built in selection API (`:h vim.ui.select()`, the `kind` `"refactoring.nvim"` is used to allow user customization). Here is an example remap to demonstrate
this functionality:

```lua
-- prompt for a refactor to apply when the remap is triggered
vim.keymap.set(
    {"n", "x"},
    "<leader>rr",
    function() require('refactoring').select_refactor() end
)
-- Note that not all refactor support both normal and visual mode
```

`select_refactor()` uses `vim.ui.input` by default to input the arguments (if
needed). If you want to use the Ex command to get the preview of the changes
you can use the `prefer_ex_cmd` option.

```lua
require('refactoring').select_refactor({prefer_ex_cmd = true})
```

#### Using Telescope<a name="config-refactoring-telescope"></a>

If you would prefer to use Telescope to choose a refactor, you can do so
using the **Telescope extension.** Here is an example
config for this setup:

```lua
-- load refactoring Telescope extension
require("telescope").load_extension("refactoring")

vim.keymap.set(
	{"n", "x"},
	"<leader>rr",
	function() require('telescope').extensions.refactoring.refactors() end
)
```

### Configuration for Debug Operations<a name="config-debug"></a>

Finally, you can configure remaps for the debug operations of this plugin like
this:

```lua
-- You can also use below = true here to to change the position of the printf
-- statement (or set two remaps for either one). This remap must be made in normal mode.
vim.keymap.set(
	"n",
	"<leader>rp",
	function() require('refactoring').debug.printf({below = false}) end
)

-- Print var

vim.keymap.set({"x", "n"}, "<leader>rv", function() require('refactoring').debug.print_var() end)
-- Supports both visual and normal mode

vim.keymap.set("n", "<leader>rc", function() require('refactoring').debug.cleanup({}) end)
-- Supports only normal mode
```

#### Customizing Printf and Print Var Statements<a name="config-debug-stringification"></a>

It is possible to override the statements used in the printf and print var
functionalities.

##### Customizing Printf Statements<a name="config-debug-stringification-printf"></a>

You can add to the printf statements for any language by adding something like
the below to your configuration:

```lua
require('refactoring').setup({
  -- overriding printf statement for cpp
  printf_statements = {
      -- add a custom printf statement for cpp
      cpp = {
          'std::cout << "%s" << std::endl;'
      }
  }
})
```

In any custom printf statement, it is possible to optionally add a max of
**one %s** pattern, which is where the debug path will go. For an example custom
printf statement, go to [this folder](lua/refactoring/tests/debug/printf),
select your language, and click on `multiple-statements/printf.config`.

##### Customizing Print Var Statements<a name="config-debug-stringification-print-var"></a>

The print var functionality can also be extended for any given language,
as shown below:

```lua
require('refactoring').setup({
  -- overriding printf statement for cpp
  print_var_statements = {
      -- add a custom print var statement for cpp
      cpp = {
          'printf("a custom statement %%s %s", %s)'
      }
  }
})
```

In any custom print var statement, it is possible to optionally add a max of
**two %s** patterns, which is where the debug path and the actual variable
reference will go, respectively. To add a literal "%s" to the string, escape the
sequence like this: `%%s`. For an example custom print var statement, go to
[this folder](lua/refactoring/tests/debug/print_var), select your language, and
view `multiple-statements/print_var.config`.

**Note:** for either of these functions, if you have multiple custom
statements, the plugin will prompt for which one should be inserted. If you
just have one custom statement in your config, it will override the default
automatically.

### Customizing Extract variable Statements<a name="config-119-custom"></a>

When performing an `extract_var` refactor operation, you can custom how the new
variable would be declared by setting configuration like the below example.

```lua
require('refactoring').setup({
  -- overriding extract statement for go
  extract_var_statements = {
    go = "%s := %s // poggers"
  }
})
```

### Configuration for Type Prompt Operations<a name="config-prompt"></a>

For certain languages like Golang, types are required for functions that return
an object(s) and parameters of functions. Unfortunately, for some parameters
and functions there is no way to automatically find their type. In those
instances, we want to provide a way to input a type instead of inserting a
placeholder value.

By default all prompts are turned off. The configuration below shows how to
enable prompts for all the languages currently supported.

```lua
require('refactoring').setup({
    -- prompt for return type
    prompt_func_return_type = {
        go = true,
        cpp = true,
        c = true,
        java = true,
    },
    -- prompt for function parameters
    prompt_func_param_type = {
        go = true,
        cpp = true,
        c = true,
        java = true,
    },
})
```
