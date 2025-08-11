-- Minimal init.lua for headless nvim integration testing
local plugin_path = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
vim.opt.runtimepath:prepend(plugin_path)

vim.cmd "filetype plugin indent on"
