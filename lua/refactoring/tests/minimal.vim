" Grabbing refactoring code
set rtp+=.

" Using local versions of plenary and nvim-treesitter if possible
" This is required for CI
set rtp+=../plenary.nvim
set rtp+=../nvim-treesitter

" If you use vim-plug if you got it locally
set rtp+=~/.vim/plugged/plenary.nvim
set rtp+=~/.vim/plugged/nvim-treesitter

" If you are using packer
set rtp+=~/.local/share/nvim/site/pack/packer/start/plenary.nvim
set rtp+=~/.local/share/nvim/site/pack/packer/start/nvim-treesitter

set autoindent
set smartindent
set tabstop=4
set expandtab
set shiftwidth=4

runtime! plugin/plenary.vim

lua <<EOF
require'nvim-treesitter.configs'.setup{
  ensure_installed = {
    'go',
    'lua',
    'python',
    'typescript',
  },
}
EOF
