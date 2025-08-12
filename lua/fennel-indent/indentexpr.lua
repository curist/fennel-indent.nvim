-- Load the compiled indent parser
local indent_parser = require("fennel-indent.indent-parser")

-- Cache for frame stacks at strategic points
local cache = {
  line_cache = {},        -- line_num -> frame_stack
  buffer_version = 0,     -- Track buffer changes
  cache_interval = 20     -- Cache every N lines (reduced for better hit rate)
}

-- Find the nearest cached frame stack before target line
local function find_nearest_cache_point(target_line)
  local best_line = 0
  for cached_line, _ in pairs(cache.line_cache) do
    if cached_line < target_line and cached_line > best_line then
      best_line = cached_line
    end
  end
  return best_line > 0 and best_line or nil
end

-- Deep copy frame stack for caching
local function copy_frame_stack(frame_stack)
  local copy = {}
  for i, frame in ipairs(frame_stack) do
    copy[i] = {}
    for k, v in pairs(frame) do
      copy[i][k] = v
    end
  end
  return copy
end

-- Get cached context or rebuild from nearest cache point
local function get_cached_context(target_line, lines)
  local current_version = vim.api.nvim_buf_get_changedtick(0)
  
  -- Invalidate cache if buffer has changed
  if cache.buffer_version ~= current_version then
    cache.line_cache = {}
    cache.buffer_version = current_version
  end
  
  local nearest_cached = find_nearest_cache_point(target_line)
  local start_line = nearest_cached or 1
  local frame_stack = {}
  
  -- Start with cached frame stack if available
  if nearest_cached then
    frame_stack = copy_frame_stack(cache.line_cache[nearest_cached])
  end
  
  -- Process lines from cache point (or start) to target
  for i = start_line, target_line - 1 do
    local line = lines[i] or ""
    indent_parser["tokenize-line"](line, i, frame_stack)
    
    -- Cache at intervals
    if i % cache.cache_interval == 0 then
      cache.line_cache[i] = copy_frame_stack(frame_stack)
    end
  end
  
  return frame_stack
end

local function indentexpr(line_num)
  -- Handle edge case: first line
  if line_num <= 1 then
    return 0
  end

  -- Wrap in pcall for error handling
  local success, result = pcall(function()
    -- Get all lines from 1 to line_num (current line)
    local lines = vim.api.nvim_buf_get_lines(0, 0, line_num, false)
    
    -- If we don't have enough lines, return 0
    if #lines < line_num then
      return 0
    end

    -- Build context using cached frame stacks
    -- This gracefully handles malformed/unclosed code per spec lines 129-135
    local frame_stack = get_cached_context(line_num, lines)

    -- Get the current line and calculate its indent
    local current_line = lines[line_num] or ""
    
    -- Get alignment settings from config (default to empty for now)
    local config = require("fennel-indent.config") 
    local align_heads = config.get_semantic_alignment() or {}
    
    -- Calculate indent for current line
    -- This handles all error cases: closer-only lines, unclosed containers, etc.
    local indent = indent_parser["calculate-indent"](current_line, line_num, frame_stack, align_heads)
    
    return indent
  end)

  -- If any error occurs, fall back to 0 indent
  if success then
    return result
  else
    return 0
  end
end

return indentexpr