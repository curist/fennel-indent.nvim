-- Load the compiled indent parser
local indent_parser = require("fennel-indent.indent-parser")

local function formatexpr()
  -- Handle v:lnum (starting line) and v:count (number of lines)
  local start_line = vim.v.lnum
  local line_count = vim.v.count
  local end_line = start_line + line_count - 1
  
  -- Debug logging (remove after fixing)
  -- print("formatexpr called: start_line=" .. start_line .. " line_count=" .. line_count .. " end_line=" .. end_line)
  
  -- Save current view to restore cursor position
  local saved_view = vim.fn.winsaveview()
  
  -- Wrap in pcall for error handling
  local success, result = pcall(function()
    -- Get all lines in buffer 
    local all_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    
    -- Get configuration for semantic alignment
    local config = require("fennel-indent.config")
    local align_heads = config.get_semantic_alignment() or {}
    
    -- Use the same approach as fix_indentation: build frame_stack incrementally
    local frame_stack = {}
    local updated_lines = {}
    
    -- Process all lines from 1 to end_line, but only update lines in range
    for line_num = 1, math.max(end_line, #all_lines) do
      local line = all_lines[line_num] or ""
      
      if line_num >= start_line and line_num <= end_line then
        -- This line is in our formatting range - apply indentation
        local trimmed = string.gsub(line, "^%s*", "")
        if trimmed == "" then
          updated_lines[line_num] = ""
        else
          local target_indent = indent_parser["calculate-indent"](line, line_num, frame_stack, align_heads)
          updated_lines[line_num] = string.rep(" ", target_indent) .. trimmed
        end
        
        -- Update frame_stack with the newly formatted line
        indent_parser["tokenize-line"](updated_lines[line_num], line_num, frame_stack)
      else
        -- This line is outside our range - just update frame_stack
        indent_parser["tokenize-line"](line, line_num, frame_stack)
      end
    end
    
    -- Apply the updated lines to the buffer
    for line_num, new_line in pairs(updated_lines) do
      local line_index = line_num - 1  -- Convert to 0-based indexing
      vim.api.nvim_buf_set_lines(0, line_index, line_index + 1, false, {new_line})
    end
    
    return 0  -- Success
  end)
  
  -- Restore view
  vim.fn.winrestview(saved_view)
  
  -- If error occurs, undo changes and return 1 (failure)
  if not success then
    vim.cmd("silent! undo")
    return 1
  end
  
  return result
end

return formatexpr