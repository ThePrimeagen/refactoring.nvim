fmt:
	echo "===> Formatting"
	stylua lua/

test:
	echo "===> Testing:"
	nvim --headless --clean \
	-u scripts/minimal.vim \
	-c "PlenaryBustedDirectory lua/refactoring/tests/"

ci-install-deps:
	./scripts/find-supported-languages.sh

lint:
	echo "===> Linting"
	luacheck lua --globals vim \
		--exclude-files lua/refactoring/tests/refactor/ \
		--exclude-files lua/refactoring/tests/debug/ \
		--no-max-line-length

pr-ready: fmt test lint

docker-build:
	docker build --no-cache . -t refactoring

pr-ready-docker:
	docker run -v $(shell pwd):/code/refactoring.nvim -t refactoring

