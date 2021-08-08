fmt:
	stylua lua/

test:
	nvim --headless --noplugin \
	-u lua/refactoring/tests/minimal.vim \
	-c "PlenaryBustedDirectory lua/refactoring/tests/ {minimal_init = 'lua/refactoring/tests/minimal.vim'}"

pr-ready: fmt test

