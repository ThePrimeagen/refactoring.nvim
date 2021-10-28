" Grabbing refactoring code
set rtp+=.

" Using local versions of plenary and nvim-treesitter if possible
" This is required for CI
set rtp+=../nvim-lspconfig
set rtp+=../plenary.nvim
set rtp+=../nvim-treesitter

set noswapfile

runtime! plugin/plenary.vim
runtime! plugin/lspconfig.vim

lua <<EOF
require'lspconfig'.tsserver.setup{}
EOF
