(local rb (require :redbean))
(local M {})

(fn read-file [path]
  "Read entire file content as string"
  (rb.slurp path))

(fn write-file [path content]
  "Write content to file with proper resource management"
  (let [file (assert (io.open path :w) (.. "Could not open file for writing: " path))]
    (local (ok err) (pcall #(file:write content)))
    (file:close)
    (if (not ok) (error err))))

(fn read-fixture [fixture-path]
  "Read fixture file from test/fixtures/"
  (read-file (.. "test/fixtures/" fixture-path)))

(fn create-temp-file [content ?extension]
  "Create a temporary file with given content using os.tmpname"
  (let [temp-name (os.tmpname)
        ;; If extension is provided, create a new name with that extension
        final-name (if ?extension
                       (.. temp-name ?extension)
                       temp-name)]
    (write-file final-name content)
    final-name))

(fn M.test-indentexpr-with-nvim [test-name]
  "Test indentexpr with headless nvim using fixture files
   
   NOTE: Uses direct Lua indentation application instead of 'gg=G' to avoid
   known Neovim core limitation where getline() returns intermediate state
   during formatting operations (vim#951, neovim#5123)
   
   test-name: name of test case (e.g. 'top-level-zero')
   
   Returns the resulting file content after nvim processes it"
  (let [input-content (read-fixture (.. test-name "/input.fnl"))
        temp-file (create-temp-file input-content)
        ;; Create lua script for direct indentation application 
        lua-script "-- Direct indentation via indentexpr (bypasses gg=G core limitation)
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
vim.api.nvim_buf_set_lines(0, 0, -1, false, result_lines)"
        temp-lua-file (create-temp-file lua-script ".lua")
        init-file "test/minimal_init.lua"
        nvim-cmd (string.format 
                   "nvim --headless -u %s %s -c 'set ft=fennel' -c 'luafile %s' -c 'write' -c 'quit' 2>/dev/null"
                   init-file temp-file temp-lua-file)
        ;; Execute nvim command  
        handle (io.popen nvim-cmd)
        _ (handle:close)
        ;; Read the result
        result (read-file temp-file)]
    ;; Clean up temp files
    (os.remove temp-file)
    (os.remove temp-lua-file)
    ;; Return result, handle nil case
    (if result
        (string.gsub result "\n$" "")
        "")))

(fn M.read-expected [test-name]
  "Read expected output for a test case"
  (let [content (read-fixture (.. test-name "/expected.fnl"))]
    ;; Remove trailing newline to match our result format
    (if content
        (string.gsub content "\n$" "")
        "")))

M
