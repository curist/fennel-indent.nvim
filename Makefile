.PHONY: test clean format compile preflight benchmark
.DEFAULT_GOAL := test

FENNEL_VERSION = 1.5.3
TEST_RUNNER_URL = https://github.com/curist/test-runner.com/releases/download/v0.1.3/test-runner.com

artifacts/test-runner.com:
	mkdir -p artifacts
	wget -O $@ ${TEST_RUNNER_URL}
	chmod +x $@

clean:
	rm -f artifacts/* lua/fennel-indent/indent-parser.lua

format:
	@fennel scripts/format-files.fnl $$(find . -iname "*.fnl" -not -path "./artifacts/*" -not -path "./test/fixtures/*" -type f)

compile: lua/fennel-indent/indent-parser.lua

lua/fennel-indent/indent-parser.lua: artifacts/test-runner.com scripts/indent-parser.fnl tasks/compile-to-lua.fnl
	@$< tasks/compile-to-lua.fnl

test: artifacts/test-runner.com lua/fennel-indent/indent-parser.lua
	@$< $(ARGS)

benchmark: artifacts/test-runner.com
	@$< tasks/benchmark-realistic.fnl

preflight: format test
