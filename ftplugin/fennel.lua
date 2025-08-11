local ok = pcall(require, "fennel-indent")
if ok then
  vim.bo.indentexpr = 'v:lua.require("fennel-indent").indentexpr()'
  vim.bo.formatexpr = 'v:lua.require("fennel-indent").formatexpr()'
end
