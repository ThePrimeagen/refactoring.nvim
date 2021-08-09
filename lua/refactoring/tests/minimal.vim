set rtp+=.
set rtp+=../plenary.nvim
set rtp+=../nvim-treesitter

runtime! plugin/plenary.vim
runtime! plugin/nvim-treesitter
runtime! plugin/refactoring.nvim

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
