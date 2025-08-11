-- Disable competing indentation systems
vim.bo.lisp = false
vim.bo.smartindent = false
vim.bo.cindent = false
vim.bo.autoindent = true  -- Keep for basic functionality

-- Set up our custom indenter
vim.bo.indentexpr = 'v:lua.require("fennel-indent.indentexpr")'
vim.bo.indentkeys = '0{,0},0),0],!^F,o,O,e,;'