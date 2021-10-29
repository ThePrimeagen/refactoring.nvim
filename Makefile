fmt:
	stylua lua/

test:
	nvim --headless --clean \
	-u scripts/minimal.vim \
	-c "PlenaryBustedDirectory lua/refactoring/tests/ {minimal_init = 'scripts/minimal.vim'}"

ci-install-deps:
	./find-supported-languages.sh

lint:
	luacheck lua --globals vim --exclude-files lua/refactoring/tests/refactor/ --no-max-line-length

pr-ready: fmt test lint

docker-build:
	docker build --no-cache . -t refactoring

docker-test:
	docker run -v $(shell pwd):/code/refactoring.nvim -t refactoring

