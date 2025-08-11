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

### Context Building
- **Look-back strategy**: Build frame stack from all previous lines
- **Edge cases**: Handle start-of-file, incomplete code, syntax errors gracefully
- **Accuracy**: Maintain spec compliance with simplified approach

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
1. **Create compilation task**: `tasks/compile-to-lua.fnl`
2. **Add Makefile rule**: `make compile` for easy building
3. **Implement naive indentexpr**: Simple, correct, unoptimized
4. **Create integration test framework**: `test/integration_helper.fnl` + headless nvim setup
5. **Test against unit tests**: Unit tests for core logic
6. **Test integration**: Parallel integration tests using headless nvim
7. **Profile performance**: Identify real bottlenecks if needed
8. **Add caching if needed**: Only after measuring actual performance

## Success Criteria
1. ✅ Reuse existing `indent-parser.fnl` logic via compilation
2. ✅ Zero-dependency pure Lua plugin
3. ✅ Handle context gracefully with look-back strategy
4. ✅ Maintain spec.md compliance
5. ✅ Lazy.nvim compatibility with proper setup function
6. ✅ Auto-enable for `.fnl` files
