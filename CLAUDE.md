# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Fennel indentation parser with comprehensive testing. Core parser in `scripts/indent-parser.fnl` implements the spec in `specs/fennel-indent-parser.md`. Neovim plugin roadmap in `task.md`.

## Development Commands

**Core Development Tasks:**
- `make test` - Run the complete test suite using redbean-based test runner
- `make lint` - Lint all Fennel files using fennel-ls
- `make format` - Format all Fennel files (requires format script)
- `make preflight` - Run lint, format, and test in sequence (pre-commit workflow)

**Testing:**
- `make test ARGS="test-top-level-zero"` - Run single test by name
- Test runner is custom-built using redbean and packaged as self-contained executable

### Testing Philosophy - TDD (Test-Driven Development)
- **ALWAYS use Test-Driven Development (TDD)**: Red → Green → Refactor
- **For new features**: Write test first, watch it fail, implement minimal code to pass, then refactor
- **For bug fixes**: Write failing test that reproduces the bug, then fix the bug
- **Unit tests**: Follow existing pattern in `test/indent-parser_test.fnl` (19 test cases)
- **CRITICAL**: Run `make preflight` after every change - this runs lint and tests
- **Format-resistant tests**: Use `table.concat` for multiline string expectations

## Key Files

- **`scripts/indent-parser.fnl`** - Core indentation engine with `fix-indentation`, `tokenize-line`, `calculate-indent`
- **`specs/fennel-indent-parser.md`** - Complete specification with all indentation rules and test cases
- **`test/indent-parser_test.fnl`** - 19 unit tests implementing the spec
- **`task.md`** - Neovim plugin implementation roadmap (equalprg + indentexpr approaches)

## Commit Message Style

**Preferred Format (keep concise):**
```
Short descriptive title

Brief 1-2 sentence explanation of what and why, if needed.
```

**Guidelines:**
- Keep commit messages concise and focused
- If you find yourself writing long lists of changes, consider breaking into multiple commits
- Focus on the "what" and "why", not exhaustive "how" details
- Use present tense ("Add feature" not "Added feature")

## Architecture Notes

- **Frame Stack**: Tracks nested contexts (:list, :vector, :table, :string) with parent relationships
- **Head Symbol Alignment**: Configurable semantic alignment (e.g., `{:if true :and true}`)
- **6-level precedence**: Closers → strings → tables/vectors → lists → comments → top-level
- **Test Runner**: Custom redbean-based executable in `artifacts/test-runner.com`
