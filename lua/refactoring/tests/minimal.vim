" Grabbing refactoring code
set rtp+=.

" Using local versions of plenary and nvim-treesitter if possible
" This is required for CI
set rtp+=../nvim-lspconfig
set rtp+=../plenary.nvim
set rtp+=../nvim-treesitter

" If you use vim-plug if you got it locally
set rtp+=~/.vim/plugged/nvim-lspconfig
set rtp+=~/.vim/plugged/plenary.nvim
set rtp+=~/.vim/plugged/nvim-treesitter

" If you are using packer
set rtp+=~/.local/share/nvim/site/pack/packer/start/nvim-lspconfig
set rtp+=~/.local/share/nvim/site/pack/packer/start/plenary.nvim
set rtp+=~/.local/share/nvim/site/pack/packer/start/nvim-treesitter

" If you are using lunarvim
set rtp+=~/.local/share/lunarvim/site/pack/packer/start/nvim-lspconfig
set rtp+=~/.local/share/lunarvim/site/pack/packer/start/plenary.nvim
set rtp+=~/.local/share/lunarvim/site/pack/packer/start/nvim-treesitter

" TODO, support NvChad because we are chad gigathundercock

set autoindent
set smartindent
set tabstop=4
set expandtab
set shiftwidth=4
set noswapfile

runtime! plugin/plenary.vim
runtime! plugin/lspconfig.vim

lua <<EOF
local required_parsers = {'go', 'lua', 'python', 'typescript', 'javascript'}
local installed_parsers = require'nvim-treesitter.info'.installed_parsers()
local to_install = vim.tbl_filter(function(parser)
  return not vim.tbl_contains(installed_parsers, parser)
end, required_parsers)
if #to_install > 0 then
  -- fixes 'pos_delta >= 0' error - https://github.com/nvim-lua/plenary.nvim/issues/52
  vim.cmd('set display=lastline')
  -- make "TSInstall*" available
  vim.cmd 'runtime! plugin/nvim-treesitter.vim'
  vim.cmd('TSInstallSync ' .. table.concat(to_install, ' '))
end

require('lspconfig').tsserver.setup{}
EOF
