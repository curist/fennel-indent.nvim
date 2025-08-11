-- Minimal init.lua for headless nvim integration testing
-- Sets up our fennel-indent plugin with basic configuration

-- Add our plugin to the runtime path
local plugin_path = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h") .. "/fennel-indent.nvim"
vim.opt.runtimepath:prepend(plugin_path)

-- Set up the plugin with default config
require('fennel-indent').setup({
  semantic_alignment = { ["if"] = true, ["when"] = true }
})

-- Set filetype to fennel for any .fnl files
vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
  pattern = "*.fnl",
  callback = function()
    vim.bo.filetype = "fennel"
  end,
})