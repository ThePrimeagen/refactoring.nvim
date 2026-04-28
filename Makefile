test:
	printf "\n======\n\n" ; \
	nvim --version | head -n 1 && echo '' ; \
	nvim --headless --clean -u ./scripts/minimal_init.lua \
		-c "lua require('mini.test').setup()" \
		-c "lua MiniTest.run()" ; \

# Use `make test_xxx` to run tests 'tests/test_xxx.lua'
TEST_MODULES = $(basename $(notdir $(wildcard tests/test_*.lua)))

$(TEST_MODULES):
	printf "\n======\n\n" ; \
	nvim --version | head -n 1 && echo '' ; \
	nvim --headless --clean -u ./scripts/minimal_init.lua \
		-c "lua require('mini.test').setup()" \
		-c "lua MiniTest.run_file('tests/$@.lua')" ; \


.PHONY: deps
deps:
	@mkdir -p deps
	git clone --filter=blob:none https://github.com/nvim-mini/mini.nvim deps/mini.nvim
	git clone --filter=blob:none https://github.com/lewis6991/async.nvim deps/async.nvim
	git clone --filter=blob:none https://github.com/mason-org/mason.nvim deps/mason.nvim
	git clone --branch main --filter=blob:none https://github.com/nvim-treesitter/nvim-treesitter deps/nvim-treesitter
	nvim --headless --clean -u scripts/minimal_init.lua -c "MasonInstall lua-language-server clangd" -c qall
	nvim --headless --clean -u scripts/minimal_init.lua -l deps/nvim-treesitter/scripts/install-parsers.lua lua java php go powershell c c_sharp cpp javascript python ruby tsx vim markdown

docs:
	nvim --headless --clean -u scripts/minimal_init.lua -c "lua require('mini.doc').generate()" -c "qa!"
