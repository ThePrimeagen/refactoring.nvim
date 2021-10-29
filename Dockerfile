FROM ubuntu:latest

# Make code directory
RUN mkdir -p code/refactoring.nvim

# update, software-properties-common, git
RUN apt-get update && \
    apt install -y software-properties-common && \
    apt install -y git

# Clone dependencies
RUN git clone https://github.com/neovim/nvim-lspconfig.git /code/nvim-lspconfig
RUN git clone https://github.com/nvim-treesitter/nvim-treesitter.git /code/nvim-treesitter
RUN git clone https://github.com/nvim-lua/plenary.nvim.git /code/plenary.nvim

# Install latest neovim, nodejs, npm, typescript + language server
# TODO: How much can be removed?
RUN add-apt-repository --yes ppa:neovim-ppa/unstable && \
    apt-get install -y neovim

# Run tests when run container
CMD cd /code/refactoring.nvim && make test

