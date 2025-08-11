-- Minimal init.lua for headless nvim integration testing
local plugin_path = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
vim.opt.runtimepath:prepend(plugin_path)

-- Manually source the ftplugin file since we're in headless mode
-- and after/ftplugin won't load automatically in this minimal setup
vim.api.nvim_create_autocmd("FileType", {
  pattern = "fennel",
  callback = function()
    vim.bo.indentexpr = 'v:lua.require("fennel-indent").indentexpr()'
    vim.bo.formatexpr = 'v:lua.require("fennel-indent").formatexpr()'
  end,
})
