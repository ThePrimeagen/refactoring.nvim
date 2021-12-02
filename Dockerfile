FROM ubuntu:latest

# Make code directory
RUN mkdir -p code/refactoring.nvim

# update, software-properties-common, git
RUN apt-get update && \
    apt install -y software-properties-common && \
    apt install -y git && \
    apt install -y curl && \
    apt install -y build-essential && \
    apt install -y luarocks

RUN luarocks install argparse && luarocks install luacheck
RUN mkdir -p /tmp/
WORKDIR /tmp

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

RUN cargo install stylua

# Clone dependencies
RUN git clone https://github.com/nvim-treesitter/nvim-treesitter.git /code/nvim-treesitter
RUN git clone https://github.com/nvim-lua/plenary.nvim.git /code/plenary.nvim

RUN add-apt-repository --yes ppa:neovim-ppa/unstable && \
    apt-get install -y neovim

# Run tests when run container
# CMD cd /code/refactoring.nvim && make ci-install-deps && make test
CMD cd /code/refactoring.nvim && \
    make lint && \
    make fmt && \
    make ci-install-deps && \
    make test

