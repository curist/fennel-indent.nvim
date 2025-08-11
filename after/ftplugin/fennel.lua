-- Disable competing indentation systems
vim.bo.lisp = false
vim.bo.smartindent = false
vim.bo.cindent = false
vim.bo.autoindent = true

-- since we are setting nolisp, let's add some keyword chars back
local symbols = { "-", "?", "!", "&", "=", ">", "<" }
local ik = vim.bo.iskeyword
for _, sym in ipairs(symbols) do
  -- match only if symbol exists as a whole item
  if not ik:match("(^|,)" .. vim.pesc(sym) .. "($|,)") then
    ik = ik .. "," .. sym
  end
end
vim.bo.iskeyword = ik
