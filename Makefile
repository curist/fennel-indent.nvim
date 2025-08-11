.PHONY: test clean format compile benchmark
.DEFAULT_GOAL := test

FENNEL_VERSION = 1.5.3
TEST_RUNNER_URL = https://github.com/curist/test-runner.com/releases/download/v0.1.3/test-runner.com

artifacts/test-runner.com:
	wget -O $@ ${TEST_RUNNER_URL}
	chmod +x $@

test: artifacts/test-runner.com
	@$< $(ARGS)

clean:
	rm artifacts/*

format:
	@fennel scripts/format-files.fnl $$(find . -iname "*.fnl" -not -path "./artifacts/*" -not -path "./test/fixtures/*" -type f)

compile: artifacts/test-runner.com
	@$< tasks/compile-to-lua.fnl

benchmark: artifacts/test-runner.com
	@$< tasks/benchmark-realistic.fnl

