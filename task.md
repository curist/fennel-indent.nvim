# Neovim Fennel Indenter Implementation Plan

## Overview
Create a zero-dependency Neovim indenter plugin using `indentexpr` only. Compile existing `scripts/indent-parser.fnl` to Lua for a pure Lua plugin that works anywhere Neovim works.

## Architecture

### Simplified `indentexpr`-only Strategy
Focus on single approach for simplicity and zero dependencies:

1. **`indentexpr` approach** - Line-by-line processing with look-back context
2. **Zero dependencies** - Compile Fennel to Lua at build time
3. **Pure Lua plugin** - No external binaries or Fennel runtime required

### Core Components

#### 1. Existing Foundation
- **`scripts/indent-parser.fnl`** - Contains robust tokenization and indentation logic
- **Key functions**: `fix-indentation`, `tokenize-line`, `calculate-indent`
- **Features**: Frame stack tracking, spec.md compliance, semantic alignment

#### 2. Build System
- **Compilation task**: `tasks/compile-to-lua.fnl` - Converts Fennel to Lua using test-runner.com
- **Makefile integration**: `make compile` runs compilation task
- **Output**: `artifacts/lua/indent-parser.lua` - Compiled pure Lua version

#### 3. Plugin Components

##### A. `indentexpr` Function  
- **Purpose**: Real-time line-by-line indentation while typing
- **API**: Lua function callable via `vim.bo.indentexpr`
- **Context Strategy**: Naive look-back approach (optimize later)
  - Read all previous lines from buffer (line 1 to line_num-1)
  - Build frame stack from those lines
  - Calculate indent for current line
- **Performance**: Start simple, add caching later if needed

##### B. Plugin Structure
```
fennel-indent.nvim/
├── lua/
│   └── fennel-indent/
│       ├── init.lua          # Plugin entry point & setup
│       ├── indent.lua        # Compiled from indent-parser.fnl
│       └── indentexpr.lua    # indentexpr implementation
├── ftplugin/
│   └── fennel.lua           # Auto-enable for .fnl files
└── README.md                # Installation & usage
```

## Implementation Details

### Build Process
1. **Compilation**: `make compile` runs `tasks/compile-to-lua.fnl`
2. **Task execution**: Uses `artifacts/test-runner.com` for Fennel environment
3. **Output**: Pure Lua code in `artifacts/lua/indent-parser.lua`

### `indentexpr` Behavior  
- **API requirement**: Function returns integer (desired indent level)
- **Context building**: Naive approach - process all previous lines (1 to line_num-1)
- **Edge cases**: Handle start-of-file, incomplete context gracefully
- **Performance**: Start simple, optimize later with caching if needed

### Neovim API Integration
```lua
-- Setting up the indenter (in ftplugin/fennel.lua)
-- Disable competing indentation systems
vim.bo.lisp = false
vim.bo.smartindent = false
vim.bo.cindent = false
vim.bo.autoindent = true  -- Keep for basic functionality

-- Set up our custom indenter
vim.bo.indentexpr = 'v:lua.require("fennel-indent").indentexpr()'
vim.bo.indentkeys = '0{,0},0),0],!^F,o,O,e,;'
```

### Installation (Lazy.nvim)
```lua
{
  'user/fennel-indent.nvim',
  ft = 'fennel',
  config = function()
    require('fennel-indent').setup({
      semantic_alignment = { if = true, when = true }
    })
  end
}
```

## Benefits

### Zero Dependencies
- **Pure Lua**: No Fennel runtime required at installation time
- **No binaries**: No external executables or `$PATH` concerns
- **Universal compatibility**: Works anywhere Neovim works

### Simplified Distribution
- **Standard plugin**: Works with any plugin manager (Lazy, Packer, etc.)
- **Easy installation**: Just add to plugin config, no additional setup
- **Spec compliance**: Maintains full spec.md-compliant indentation logic

## Technical Challenges

### Performance Considerations
- **Naive implementation**: Processing all previous lines for each indent call
- **Potential bottleneck**: Large files with many indentation calls
- **Solution**: Start simple, add line-content-based caching if needed

### Context Building & Error Handling (Per Spec Lines 129-135)
- **Malformed/unclosed containers**: Build delimiter stack by scanning up to target line, treat current stack as authoritative
- **Inside unclosed container**: Apply container's rule (list base, vector/table anchor, string_anchor; continuation if eligible)  
- **Closer-only line with no matching opener**: Indent as top level = 0
- **Unclosed multiline string**: Continue using string_anchor for all subsequent lines until closed
- **Look-back strategy**: Build frame stack from all previous lines gracefully handling incomplete context

## Testing Strategy

### Unit Tests (Existing)
- **Unit tests**: 19 existing tests in `test/indent-parser_test.fnl` validate core parser logic
- **Spec compliance**: Tests cover all indentation rules from `specs/fennel-indent-parser.md`

### Integration Tests (New)
- **Headless Neovim**: Test actual plugin behavior using `nvim --headless`
- **Integration helper**: `test/integration_helper.fnl` with temp file management
  ```fennel
  ;; Helper creates temp files, runs headless nvim, captures results
  (test-indentexpr-with-nvim input expected)
  ```
- **Parallel tests**: Each existing unit test gets integration equivalent
- **Real environment**: Tests compiled Lua plugin in actual Neovim with proper setup

### Test Implementation
```fennel
;; test/integration_test.fnl
{:test-integration-top-level-zero
 (fn []
   (testing "headless nvim matches fix-indentation results"
     #(let [input "  foo\n  (bar)"
            expected "foo\n(bar)"  
            result (helper.test-indentexpr-with-nvim input expected)]
        (assert.= expected result))))
        
 :test-integration-list-closer-base
 (fn []
   (testing "list closer alignment via indentexpr"
     #(let [input "(foo\n  x\n  y\n)"
            expected "(foo\n  x\n  y\n  )"
            result (helper.test-indentexpr-with-nvim input expected)]
        (assert.= expected result))))}
```

### Performance & Edge Cases
- **Performance measurement**: Profile naive implementation on large files
- **Edge case handling**: Test start-of-file, syntax errors, incomplete context
- **Consistency validation**: Ensure line-by-line indentexpr matches whole-file results

## Development Workflow

### Phase 1: Foundation ✅ COMPLETE
- [x] **Create compilation task**: `tasks/compile-to-lua.fnl` - Define exact Fennel-to-Lua conversion process
- [x] **Add Makefile rule**: `make compile` for easy building
- [x] **Define Plugin API Reference**: Function signatures and return types for indentexpr interface
- [x] **Create plugin directory structure**: Exact file paths and module exports in `fennel-indent.nvim/`

### Phase 2: Core Implementation ✅ COMPLETE
- [x] **Implement naive indentexpr**: Simple, correct, unoptimized line-by-line processor
  - ✅ `fennel-indent.nvim/lua/fennel-indent/indentexpr.lua` - Core indentexpr implementation
  - ✅ Loads compiled `artifacts/lua/indent-parser.lua` with path resolution
  - ✅ Line-by-line processing with frame stack building from previous lines
  - ✅ Error handling with pcall fallback to 0 indent
- [x] **Add error handling**: Handle malformed/unclosed code per spec (lines 129-135 in specs/)
  - ✅ All error cases handled by existing compiled logic (closer-only lines, unclosed containers, etc.)
  - ✅ Graceful fallback on any errors via pcall wrapper
- [x] **Create integration test framework**: `test/integration_helper.fnl` + headless nvim setup with temp file patterns
  - ✅ `test/integration_helper.fnl` - Fixture-based testing with `rb.slurp` and temp files
  - ✅ `test/fixtures/` - Input/expected pairs for test cases (top-level-zero, list-closer-base, table-anchor)
  - ✅ `test/minimal_init.lua` - Neovim init for headless testing with plugin setup
  - ✅ `test/apply_indent.lua` - Direct indentation application via lua (bypasses `=` command issues)
  - ✅ Individual integration tests pass and match unit test results
  - ✅ Fixed: Multi-test timing/state conflicts resolved with `os.tmpname()` 
  - ⚠️ **Critical Known Limitation**: `gg=G` formatting commands have inconsistent behavior due to Neovim/Vim core issue

## Known Issues & Limitations

### `gg=G` and Formatting Command Inconsistency

**Issue**: The `=` (format) command in Neovim has inconsistent behavior with custom `indentexpr` functions.

**Root Cause**: During formatting operations like `gg=G`, Neovim's `getline()` function returns modified/joined line content in intermediate states, causing `vim.api.nvim_buf_get_lines()` calls within our `indentexpr` to see different content than expected. This is a documented limitation affecting both Vim and Neovim (Issues: [vim#951](https://github.com/vim/vim/issues/951), [neovim#5123](https://github.com/neovim/neovim/issues/5123)).

**Impact**: 
- `indentexpr` works correctly for single-line indentation (Insert mode, `==`, etc.)
- `gg=G` may produce inconsistent results due to intermediate line state during formatting
- Integration tests use direct Lua indentation application to avoid this core limitation

**Current Status**: Working around limitation - plugin functions correctly for normal indentation use cases

### Phase 2.5: formatexpr Implementation (HIGH PRIORITY)
**NEXT TODO**: Implement `formatexpr` in addition to `indentexpr` to provide reliable `gq`/`gg=G` support
- [ ] **Research formatexpr API**: Understand formatexpr vs indentexpr differences and implementation requirements  
- [ ] **Implement formatexpr function**: Create `fennel-indent.nvim/lua/fennel-indent/formatexpr.lua`
- [ ] **Integrate with plugin**: Set both `indentexpr` and `formatexpr` in `ftplugin/fennel.lua`
- [ ] **Test formatexpr with gg=G**: Verify formatting commands work reliably
- [ ] **Update integration tests**: Test both indentexpr and formatexpr approaches
- [ ] **Document formatexpr usage**: Add to plugin README and configuration guide

### Phase 3: Validation & Polish
- [ ] **Test against unit tests**: Unit tests for core logic
- [ ] **Test integration**: Parallel integration tests using headless nvim  
- [ ] **Profile performance**: Identify real bottlenecks if needed with specific benchmarking methodology
- [ ] **Add caching if needed**: Only after measuring actual performance

## Success Criteria
1. ✅ Reuse existing `indent-parser.fnl` logic via compilation
2. ✅ Zero-dependency pure Lua plugin
3. ✅ Handle context gracefully with look-back strategy
4. ✅ Maintain spec.md compliance
5. ✅ Lazy.nvim compatibility with proper setup function
6. ✅ Auto-enable for `.fnl` files
