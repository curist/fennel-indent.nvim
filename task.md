# Neovim Fennel Indenter Performance Optimization Plan

## Performance Analysis Summary

### Current Performance Issues
**Benchmarking Results** (5000 lines in 43.1 seconds):
- Performance: 0.1 lines/ms (ACCEPTABLE but needs improvement)
- **Quadratic complexity**: O(n²) behavior due to naive context building
- **Root cause**: `indentexpr` rebuilds entire frame stack from line 1 for every indentation

### Key Bottlenecks Identified

1. **Naive Context Building** (`scripts/indent-parser.fnl:33-119`):
   - Every `indentexpr` call processes all lines from 1 to target line
   - 5000 lines = ~12.5M tokenization operations (n²/2 complexity)

2. **Expensive String Operations**:
   - Heavy regex usage: `string.match`, `string.gsub` per character
   - Character-by-character processing in tokenization loops

3. **Neovim API Overhead**:
   - Multiple `nvim_buf_get_lines()` calls per indentation
   - No caching between consecutive indentation calls

## Performance Optimization Strategy

### Phase 1: Smart Caching System (High Impact - Target 10-50x improvement)

#### Frame Stack Caching
```lua
-- Cache frame stack at strategic points
local line_cache = {}        -- line_num -> frame_stack
local buffer_version = 0     -- Track buffer changes

function get_cached_context(target_line)
  local last_cached = find_nearest_cache_point(target_line)
  if last_cached then
    return rebuild_from_cache(last_cached, target_line)  -- O(delta) vs O(n)
  else
    return rebuild_from_start(target_line)  -- Fallback
  end
end
```

#### Cache Invalidation Strategy
- **Buffer change detection**: Track `vim.api.nvim_buf_get_changedtick()`
- **Smart invalidation**: Only clear cache entries after modified lines
- **Cache points**: Store frame stack every N lines (e.g., every 50-100 lines)

### Phase 2: Tokenization Optimizations (Medium Impact - Target 2-3x improvement)

#### String Processing Optimizations
- Replace character-by-character loops with pattern matching
- Pre-compile frequently used regex patterns
- Optimize string escape handling with lookup tables
- Use string slicing instead of repeated `string.sub` calls

#### Algorithmic Improvements
- Early termination for comment-only lines
- Skip processing when frame stack unchanged
- Batch process multiple delimiter operations

### Phase 3: Buffer Change Detection (Medium Impact - Target 2-5x for repeated ops)

#### Incremental Updates
- Track which lines have been modified since last cache
- Only rebuild affected portions of frame stack
- Preserve cache for unchanged file regions

#### Smart Cache Warming
- Pre-populate cache during idle periods
- Background processing for large files
- Progressive cache building during editing

### Phase 4: Memory and API Optimizations (Low Impact - Target 1.5-2x improvement)

#### Memory Management
- Reuse frame objects instead of creating new ones
- Pool allocation for frequently created objects
- Lazy loading of parser modules

#### API Efficiency  
- Batch `nvim_buf_get_lines()` calls
- Minimize string allocations
- Use buffer-local variables for cache storage

## Implementation Roadmap

### Phase 1: Core Caching (Immediate Priority)
- [ ] Implement frame stack caching in `indentexpr.lua`
- [ ] Add buffer change detection
- [ ] Create cache invalidation logic
- [ ] Test with realistic benchmarks

### Phase 2: Tokenization Performance (Next Priority)
- [ ] Profile `tokenize-line` function bottlenecks
- [ ] Implement string processing optimizations
- [ ] Add pattern pre-compilation
- [ ] Benchmark improvements

### Phase 3: Advanced Optimizations (Future)
- [ ] Implement incremental cache updates
- [ ] Add background cache warming
- [ ] Fine-tune cache point placement
- [ ] Memory usage optimization

## Success Metrics

### Performance Targets
- **Phase 1**: >1 line/ms (10x improvement from current 0.1 lines/ms)
- **Phase 2**: >3 lines/ms (combined 30x improvement)  
- **Phase 3**: >5 lines/ms (50x improvement)
- **Final Goal**: >10 lines/ms (100x improvement - "EXCELLENT" performance)

### Testing Strategy
- Use existing `tasks/benchmark-realistic.fnl` for performance measurement
- Test with files of varying sizes: 100, 500, 1000, 2000, 5000 lines
- Ensure correctness with existing unit and integration tests
- Profile memory usage alongside performance improvements

## Current Status
- ✅ **Foundation Complete**: Working plugin with formatexpr/indentexpr
- ✅ **Performance Analysis**: Identified O(n²) bottleneck
- ✅ **Benchmarking Infrastructure**: Realistic performance testing available
- 🎯 **Next Step**: Implement Phase 1 caching system
