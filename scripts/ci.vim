" Grabbing refactoring code
set rtp+=.

" Using local versions of plenary and nvim-treesitter if possible
" This is required for CI
set rtp+=../plenary.nvim
set rtp+=../nvim-treesitter

set noswapfile

runtime! plugin/plenary.vim
