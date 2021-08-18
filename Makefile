fmt:
	stylua lua/

test:
	nvim --headless --clean \
	-u lua/refactoring/tests/minimal.vim \
	-c "PlenaryBustedDirectory lua/refactoring/tests/ {minimal_init = 'lua/refactoring/tests/minimal.vim'}"

lint:
	luacheck lua --globals vim --exclude-files lua/refactoring/tests/refactor/ --no-max-line-length

pr-ready: fmt test lint

