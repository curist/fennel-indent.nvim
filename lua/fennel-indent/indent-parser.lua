local leading_spaces_pattern = "^( *)"
local whitespace_only_pattern = "^%s*$"
local comment_start_pattern = "^%s*;"
local closer_chars = {[")"] = true, ["]"] = true, ["}"] = true}
local opener_chars = {["("] = "list", ["["] = "vector", ["{"] = "table", ["\""] = "string"}
local whitespace_chars = {[" "] = true, ["\9"] = true, ["\n"] = true, ["\r"] = true}
local function get_leading_spaces(line)
  local spaces = string.match(line, leading_spaces_pattern)
  return #(spaces or "")
end
local function line_starts_with_closer_3f(line)
  local trimmed = string.match(line, "^%s*(.*)")
  return (trimmed and (#trimmed > 0) and closer_chars[string.sub(trimmed, 1, 1)])
end
local function comment_only_line_3f(line)
  return (string.match(line, whitespace_only_pattern) or string.match(line, comment_start_pattern))
end
local function pop_matching_21(stack, closer)
  local want
  if (closer == ")") then
    want = "list"
  elseif (closer == "]") then
    want = "vector"
  elseif (closer == "}") then
    want = "table"
  else
    want = nil
  end
  if want then
    local i = #stack
    while ((i > 0) and (stack[i].type ~= want)) do
      i = (i - 1)
    end
    if (i > 0) then
      return table.remove(stack, i)
    else
      return nil
    end
  else
    return nil
  end
end
local function tokenize_line(line, line_num, frame_stack)
  local len = #line
  local current_indent = get_leading_spaces(line)
  local i = 1
  local in_string = false
  local escape_next = false
  if ((#frame_stack > 0) and (frame_stack[#frame_stack].type == "string")) then
    in_string = true
  else
  end
  if comment_only_line_3f(line) then
    return
  else
  end
  while (i <= len) do
    local char = string.sub(line, i, i)
    if escape_next then
      escape_next = false
    elseif in_string then
      if (char == "\\") then
        escape_next = true
      elseif (char == "\"") then
        in_string = false
        if ((#frame_stack > 0) and (frame_stack[#frame_stack].type == "string")) then
          table.remove(frame_stack)
        else
        end
      else
      end
    elseif (char == ";") then
      break
    else
      local parent
      if (#frame_stack > 0) then
        parent = frame_stack[#frame_stack]
      else
        parent = nil
      end
      if (char == "\"") then
        in_string = true
        table.insert(frame_stack, {type = "string", indent = current_indent, open_col = (i - 1), open_line = line_num, parent = parent})
      elseif (char == "(") then
        local frame = {type = "list", indent = current_indent, open_col = (i - 1), open_line = line_num, parent = parent}
        local j = (i + 1)
        while ((j <= len) and whitespace_chars[string.sub(line, j, j)]) do
          j = (j + 1)
        end
        if (j <= len) then
          local head_start = j
          while true do
            local and_9_ = (j <= len)
            if and_9_ then
              local c = string.sub(line, j, j)
              and_9_ = not (whitespace_chars[c] or opener_chars[c] or closer_chars[c] or (c == ";") or (c == "\""))
            end
            if not and_9_ then break end
            j = (j + 1)
          end
          if (j > head_start) then
            frame.head_symbol = string.sub(line, head_start, (j - 1))
            frame.head_col = (head_start - 1)
            while ((j <= len) and whitespace_chars[string.sub(line, j, j)]) do
              j = (j + 1)
            end
            if ((j <= len) and (string.sub(line, j, j) ~= ";")) then
              frame.first_arg_col = (j - 1)
            else
            end
          else
          end
        else
        end
        table.insert(frame_stack, frame)
      elseif (char == "[") then
        table.insert(frame_stack, {type = "vector", indent = current_indent, open_col = (i - 1), open_line = line_num, parent = parent})
      elseif (char == "{") then
        table.insert(frame_stack, {type = "table", indent = current_indent, open_col = (i - 1), open_line = line_num, parent = parent})
      elseif closer_chars[char] then
        pop_matching_21(frame_stack, char)
      else
      end
    end
    i = (i + 1)
  end
  return nil
end
local function is_descendant_3f(f, outer)
  local p = f.parent
  while p do
    if (p == outer) then
      return true
    else
    end
    p = p.parent
  end
  return false
end
local function find_innermost_opener(stack, current_line_num)
  if (#stack > 0) then
    local outer = nil
    for i = #stack, 1, -1 do
      if (stack[i].type == "list") then
        outer = stack[i]
        break
      else
      end
    end
    if outer then
      local threshold = (outer.head_col or outer.open_col)
      for i = #stack, 1, -1 do
        local f = stack[i]
        if ((f.type == "list") and (f ~= outer) and is_descendant_3f(f, outer) and (f.open_line < current_line_num) and (f.open_col > threshold)) then
          return f
        else
        end
      end
      return nil
    else
      return nil
    end
  else
    return nil
  end
end
local function calculate_indent(line, line_num, frame_stack, align_heads)
  local top_frame
  if (#frame_stack > 0) then
    top_frame = frame_stack[#frame_stack]
  else
    top_frame = nil
  end
  if line_starts_with_closer_3f(line) then
    local first = string.sub(string.match(line, "^%s*(.*)"), 1, 1)
    local want
    if (first == ")") then
      want = "list"
    elseif (first == "]") then
      want = "vector"
    elseif (first == "}") then
      want = "table"
    else
      want = nil
    end
    local indent = 0
    if want then
      for i = #frame_stack, 1, -1 do
        local frame = frame_stack[i]
        if (frame.type == want) then
          if (want == "list") then
            local base0 = (frame.indent + 2)
            local base
            if (frame.open_col > frame.indent) then
              base = math.max(base0, (frame.open_col + 2))
            else
              base = base0
            end
            indent = base
          else
            indent = (frame.open_col + 1)
          end
          break
        else
        end
      end
    else
    end
    return indent
  elseif (top_frame and (top_frame.type == "string")) then
    return (top_frame.open_col + 1)
  elseif (top_frame and (top_frame.type == "table")) then
    return (top_frame.open_col + 1)
  elseif (top_frame and (top_frame.type == "vector")) then
    return (top_frame.open_col + 1)
  elseif (top_frame and (top_frame.type == "list")) then
    local base0
    if (top_frame.head_symbol and top_frame.first_arg_col and align_heads[top_frame.head_symbol]) then
      base0 = top_frame.first_arg_col
    else
      base0 = (top_frame.indent + 2)
    end
    local base
    if (top_frame.open_col > top_frame.indent) then
      base = math.max(base0, (top_frame.open_col + 2))
    else
      base = base0
    end
    local inner_opener = find_innermost_opener(frame_stack, line_num)
    local continuation_col
    if inner_opener then
      continuation_col = (inner_opener.first_arg_col or (inner_opener.open_col + 2))
    else
      continuation_col = base
    end
    return math.max(base, continuation_col)
  elseif comment_only_line_3f(line) then
    if not top_frame then
      return 0
    elseif (top_frame.type == "table") then
      return (top_frame.open_col + 1)
    elseif (top_frame.type == "vector") then
      return (top_frame.open_col + 1)
    elseif (top_frame.type == "list") then
      local base0
      if (top_frame.head_symbol and top_frame.first_arg_col and align_heads[top_frame.head_symbol]) then
        base0 = top_frame.first_arg_col
      else
        base0 = (top_frame.indent + 2)
      end
      local base
      if (top_frame.open_col > top_frame.indent) then
        base = math.max(base0, (top_frame.open_col + 2))
      else
        base = base0
      end
      local inner_opener = find_innermost_opener(frame_stack, line_num)
      local continuation_col
      if inner_opener then
        continuation_col = (inner_opener.first_arg_col or (inner_opener.open_col + 2))
      else
        continuation_col = base
      end
      return math.max(base, continuation_col)
    elseif (top_frame.type == "string") then
      return (top_frame.open_col + 1)
    else
      return 0
    end
  else
    return 0
  end
end
local function fix_indentation(input, _3falign_heads)
  local lines
  do
    local tbl_21_ = {}
    local i_22_ = 0
    for line in string.gmatch((input .. "\n"), "([^\n]*)\n") do
      local val_23_ = line
      if (nil ~= val_23_) then
        i_22_ = (i_22_ + 1)
        tbl_21_[i_22_] = val_23_
      else
      end
    end
    lines = tbl_21_
  end
  local align_heads = (_3falign_heads or {})
  local frame_stack = {}
  local result_lines = {}
  for _, line in ipairs(lines) do
    if (#line > 300) then
      return input
    else
    end
  end
  for line_num, line in ipairs(lines) do
    local trimmed = string.gsub(line, "^%s*", "")
    if (trimmed == "") then
      table.insert(result_lines, "")
    else
      local target_indent = calculate_indent(line, line_num, frame_stack, align_heads)
      local formatted_line = (string.rep(" ", target_indent) .. trimmed)
      tokenize_line(formatted_line, line_num, frame_stack)
      table.insert(result_lines, formatted_line)
    end
  end
  return table.concat(result_lines, "\n")
end
return {["fix-indentation"] = fix_indentation, ["tokenize-line"] = tokenize_line, ["calculate-indent"] = calculate_indent}