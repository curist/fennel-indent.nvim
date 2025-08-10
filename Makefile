.PHONY: test clean lint format preflight
.DEFAULT_GOAL := test

FENNEL_VERSION = 1.5.3
TEST_RUNNER_URL = https://github.com/curist/test-runner.com/releases/download/v0.1.1/test-runner.com

artifacts/test-runner.com:
	wget -O $@ ${TEST_RUNNER_URL}
	chmod +x $@

test: artifacts/test-runner.com
	@$< $(ARGS)

clean:
	rm artifacts/*

lint:
	@fennel-ls --lint $$(find . -iname "*.fnl" -type f)

format:
	@fennel scripts/format-files.fnl $$(find . -iname "*.fnl" -not -path "./artifacts/*" -type f)

preflight: lint format test

