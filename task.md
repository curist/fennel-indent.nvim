# Neovim Fennel Indenter Implementation Plan

## Overview
Create a Neovim indenter plugin that reuses the existing `scripts/indent-parser.fnl` to provide both whole-file and line-by-line indentation for Fennel code.

## Architecture

### Dual Approach Strategy
Support both indentation methods for maximum performance and flexibility:

1. **`equalprg` approach** - Whole-file/range processing
2. **`indentexpr` approach** - Line-by-line processing

### Core Components

#### 1. Existing Foundation
- **`scripts/indent-parser.fnl`** - Contains robust tokenization and indentation logic
- **Key functions**: `fix-indentation`, `tokenize-line`, `calculate-indent`
- **Features**: Frame stack tracking, spec.md compliance, semantic alignment

#### 2. New Components to Implement

##### A. `equalprg` Script
- **Purpose**: Handle range-based indentation (e.g., `=5j`, `gg=G`, visual selections)
- **Input**: Selected lines via stdin
- **Output**: Formatted lines to stdout
- **Context Strategy**: 
  - For partial ranges: Assume first line's indentation is correct
  - Infer initial frame stack state from first line's indent level
  - Process remaining lines using inferred context

##### B. `indentexpr` Function  
- **Purpose**: Real-time line-by-line indentation while typing
- **API**: Lua function callable via `vim.bo.indentexpr`
- **Context Strategy**: Look-back approach
  - Read 15-20 previous lines from buffer
  - Assume their indentation is correct
  - Build frame stack from those lines
  - Calculate indent for current line

##### C. Neovim Plugin Structure
```
fennel-indent.nvim/
├── lua/
│   └── fennel-indent/
│       ├── init.lua          # Plugin entry point
│       ├── equalprg.lua      # equalprg wrapper
│       └── indentexpr.lua    # indentexpr function
├── bin/
│   └── fennel-equalprg       # Executable for equalprg
└── scripts/
    └── indent-parser.fnl     # Copied from existing project
```

## Implementation Details

### `equalprg` Behavior
- **Range handling**: `=` + motion sends only selected lines to stdin
- **Context inference**: For partial ranges, assume first line represents correct base indentation level
- **Algorithm**:
  1. Parse first line to determine indentation level
  2. Build plausible frame stack to explain that indentation
  3. Process remaining lines normally

### `indentexpr` Behavior  
- **API requirement**: Function returns integer (desired indent level)
- **Context building**: Look back 15-20 lines to build frame stack
- **Edge cases**: Handle start-of-file, incomplete context gracefully
- **Performance**: Cache frame stack when possible

### Neovim API Integration
```lua
-- Setting up the indenter
vim.bo.equalprg = 'fennel-equalprg'
vim.bo.indentexpr = 'v:lua.require("fennel-indent").indentexpr()'
vim.bo.indentkeys = '0{,0},0),0],!^F,o,O,e,;'
```

## Benefits

### Performance Optimization
- **Whole-file operations** (`gg=G`): Use `equalprg` for maximum accuracy with full context
- **Interactive editing**: Use `indentexpr` for responsive line-by-line indenting
- **Best of both worlds**: User gets optimal performance for different scenarios

### Accuracy
- **Full context**: `equalprg` can build complete frame stack for accurate indentation
- **Reasonable approximation**: `indentexpr` uses look-back for good-enough accuracy
- **Spec compliance**: Both approaches leverage the same spec.md-compliant core logic

## Technical Challenges

### Context Limitations
- **`equalprg`**: May receive partial file content, need to infer context
- **`indentexpr`**: Single-line context, need to reconstruct surrounding state
- **Solution**: Intelligent context inference and look-back strategies

### State Management
- **Frame stack consistency**: Ensure both approaches produce similar results
- **Caching**: Optimize `indentexpr` performance with intelligent caching
- **Edge cases**: Handle incomplete code, syntax errors gracefully

## Testing Strategy
- **Unit tests**: Test context inference logic
- **Integration tests**: Compare `equalprg` vs `indentexpr` results
- **Real-world scenarios**: Test with complex Fennel codebases
- **Performance tests**: Measure response time for large files

## Installation & Usage
- **Plugin manager**: Compatible with lazy.nvim, packer.nvim, etc.
- **File type detection**: Auto-enable for `.fnl` files
- **Configuration**: Optional semantic alignment settings
- **Fallback**: Graceful degradation if Fennel runtime unavailable

## Success Criteria
1. ✅ Reuse existing `indent-parser.fnl` logic
2. ✅ Support both `equalprg` and `indentexpr` approaches
3. ✅ Handle partial context gracefully
4. ✅ Maintain spec.md compliance
5. ✅ Good performance for interactive editing
6. ✅ Accurate results for whole-file formatting
