-- Load the compiled indent parser
local indent_parser = require("fennel-indent.indent-parser")

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

    -- Build context by processing all previous lines (1 to line_num-1)
    -- This gracefully handles malformed/unclosed code per spec lines 129-135
    local frame_stack = {}
    for i = 1, line_num - 1 do
      local line = lines[i] or ""
      -- Process each line to build frame stack
      indent_parser["tokenize-line"](line, i, frame_stack)
    end

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