# fennel-indent.nvim

Zero-dependency Neovim plugin providing spec-compliant indentation for Fennel code using both `indentexpr` and `formatexpr`.

## Features

- **✅ Spec-compliant**: Implements the complete [Fennel indentation specification](specs/fennel-indent-parser.md)
- **🚀 Zero dependencies**: Pure Lua plugin, no Fennel runtime or external binaries required
- **⚡ High performance**: Optimized caching system with 3x performance improvement
- **🔧 Dual approach**: Both line-by-line (`indentexpr`) and format commands (`formatexpr`)
- **🎯 Works everywhere**: Compatible with any Neovim installation and plugin manager

## Installation

### Lazy.nvim

```lua
{
  'curist/fennel-indent.nvim',
  ft = 'fennel',
  opts = {
    -- Optional: Configure semantic alignment (default shown)
    semantic_alignment = { 'if', 'and', 'or', '..', '->', '->>', '-?>', '-?>>' }
  }
}
```

### Packer

```lua
use {
  'curist/fennel-indent.nvim',
  ft = 'fennel',
  config = function()
    require('fennel-indent').setup({
      semantic_alignment = { 'if', 'and', 'or', '..', '->', '->>', '-?>', '-?>>' }
    })
  end
}
```

### Manual Installation

```bash
git clone https://github.com/curist/fennel-indent.nvim ~/.config/nvim/pack/plugins/start/fennel-indent.nvim
```

## Usage

The plugin automatically enables for `.fnl` files. Both approaches work seamlessly:

### Line-by-line Indentation (`indentexpr`)

- **Insert mode**: Automatic indentation while typing
- **`==`**: Indent current line
- **`=ap`**: Indent around paragraph
- **Manual trigger**: Any standard Vim indentation command

### Format Commands (`formatexpr`)

- **`gq`**: Format selection or motion
- **`gqG`**: Format entire file (recommended for large files - up to 333x faster than `gg=G`)
- **`gqap`**: Format around paragraph

Both approaches produce identical, spec-compliant results.

## Configuration

### Default Configuration

```lua
require('fennel-indent').setup({
  -- Default semantic alignment for multi-token forms (vector format)
  semantic_alignment = { 'if', 'and', 'or', '..', '->', '->>', '-?>', '-?>>' }
})
```

### Semantic Alignment Examples

With semantic alignment enabled:

```fennel
;; ✅ Aligned to first argument
(if condition-here
    then-clause
    else-clause)

;; ✅ Threading macros align consistently  
(-> data
    (map transform)
    (filter predicate)
    (reduce combine))

;; ✅ Boolean operators align
(and condition1
     condition2
     condition3)
```

With semantic alignment disabled:

```fennel
;; ✅ Structural indentation (base + 2)
(if condition-here
  then-clause
  else-clause)
```

## Indentation Rules

The plugin implements comprehensive indentation rules:

### Lists
```fennel
(function-name arg1
               arg2)  ; Arguments align to first arg

(f                    ; Long function names use structural indent
  arg1
  arg2)
```

### Tables & Vectors
```fennel
{:key1 value1
 :key2 value2}        ; Anchor at opening brace + 1

[item1
 item2
 item3]               ; Vector elements align
```

### Nested Structures
```fennel
(let [binding1 value1
      binding2 {:nested :table
                :with :values}]
  body)
```

### Comments
```fennel
;; Top-level comments at column 0
(function
  ;; Inner comments follow context rules
  body)
```

For complete specification, see [specs/fennel-indent-parser.md](specs/fennel-indent-parser.md).

## Performance

Real-world benchmarks comparing different formatting approaches:

| Lines | `gg=G` (indentexpr) | `gqG` (formatexpr) | Performance Difference |
|-------|--------------------|--------------------|------------------------|
| 100   | 44ms (2.3/ms)      | 33ms (3.0/ms)      | 1.3x faster            |
| 500   | 207ms (2.4/ms)     | 37ms (13.7/ms)     | **5.7x faster**        |
| 1000  | 726ms (1.4/ms)     | 37ms (27.1/ms)     | **19.7x faster**       |
| 2000  | 2.9s (0.7/ms)      | 42ms (47.6/ms)     | **68.6x faster**       |
| 5000  | 18.6s (0.3/ms)     | 56ms (89.7/ms)     | **333x faster**        |

**💡 Key Takeaway**: Use `gqG` instead of `gg=G` for whole-file formatting on large files.

**Why the difference?**
- **`gg=G`**: Calls `indentexpr` line-by-line (O(n²) despite caching)
- **`gqG`**: Uses `formatexpr` with range-based processing (O(n), single-pass)

**Performance optimizations included:**
- Smart caching system for `indentexpr` (3x improvement over naive implementation)
- Tokenization optimizations with lookup tables and early exits
- Single-pass `formatexpr` using efficient `fix-indentation` function

## Technical Details

### Architecture

- **Core parser**: Compiled from `scripts/indent-parser.fnl` to pure Lua with tokenization optimizations
- **Build system**: Uses custom redbean-based test runner  
- **Frame stack**: Tracks nested contexts with precedence rules
- **Smart caching**: Caches frame stacks every 20 lines, rebuilds from nearest cache point

### Dual Implementation Benefits

- **`indentexpr`**: Real-time indentation while typing, works with `==` and similar commands
- **`formatexpr`**: Reliable formatting that bypasses known Vim/Neovim `gg=G` limitations
- **Consistent results**: Both approaches use identical core logic

### Known Limitations

**Performance Note**: The `gg=G` command calls `indentexpr` line-by-line, resulting in O(n²) behavior for large files. Use `gqG` (formatexpr) for significantly better performance on files >500 lines.

## Development

### Testing

```bash
make test          # Run all tests (19 unit + 6 integration)
make lint          # Lint Fennel files
make preflight     # Run lint + test (pre-commit workflow)
```

### Build System

```bash
make compile       # Compile Fennel to Lua
make benchmark     # Run performance tests
```

### Test-Driven Development

The project follows strict TDD methodology with comprehensive test coverage:

- **Unit tests**: 19 tests covering all indentation rules
- **Integration tests**: 6 tests using headless Neovim
- **Performance tests**: Benchmarking on large files
- **Spec compliance**: All tests implement [fennel-indent-parser.md](specs/fennel-indent-parser.md)

## Contributing

1. Follow TDD: Write tests first, then implement
2. Run `make preflight` before commits
3. All changes must pass the complete test suite
4. Maintain spec compliance with `specs/fennel-indent-parser.md`

## AI / LLM Usage

This project was developed with assistance from large language models (LLMs).
LLMs were used to help with:

* Drafting and iterating on code implementations
* Generating boilerplate and repetitive structures
* Refining documentation and comments

## License

MIT License - see [LICENSE](LICENSE) file for details.
