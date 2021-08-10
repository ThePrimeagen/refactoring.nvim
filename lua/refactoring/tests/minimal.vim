set rtp+=.
set rtp+=../plenary.nvim
set rtp+=../nvim-treesitter
set rtp+=../popup.nvim/


runtime! plugin/popup.nvim/
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
