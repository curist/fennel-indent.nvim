-- Apply indentation using our indentexpr to all lines in the current buffer
local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
local indenter = require('fennel-indent')
local result_lines = {}

for i, line in ipairs(lines) do
  local trimmed = string.gsub(line, '^%s*', '')
  if trimmed == '' then
    table.insert(result_lines, '')
  else
    vim.v.lnum = i
    local indent = indenter.indentexpr()
    table.insert(result_lines, string.rep(' ', indent) .. trimmed)
  end
end

vim.api.nvim_buf_set_lines(0, 0, -1, false, result_lines)