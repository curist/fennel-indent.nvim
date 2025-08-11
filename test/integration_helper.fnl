(local rb (require :redbean))
(local M {})

(fn read-file [path]
  "Read entire file content as string"
  (rb.slurp path))

(fn write-file [path content]
  "Write content to file"
  (let [file (io.open path :w)]
    (if file
        (do (file:write content)
            (file:close))
        (error (.. "Could not write file: " path)))))

(fn read-fixture [fixture-path]
  "Read fixture file from test/fixtures/"
  (read-file (.. "test/fixtures/" fixture-path)))

(fn create-temp-file [content]
  "Create a temporary .fnl file with given content"
  (let [temp-name (.. "/tmp/fennel-indent-test-" (os.time) "-" (math.random 100000) "-" (math.random 100000) ".fnl")]
    (write-file temp-name content)
    temp-name))

(fn M.test-indentexpr-with-nvim [test-name]
  "Test indentexpr with headless nvim using fixture files
   
   test-name: name of test case (e.g. 'top-level-zero')
   
   Returns the resulting file content after nvim processes it"
  (let [input-content (read-fixture (.. test-name "/input.fnl"))
        temp-file (create-temp-file input-content)
        init-file "test/minimal_init.lua"
        ;; Use external lua file to apply indentation  
        nvim-cmd (string.format 
                   "nvim --headless -u %s %s -c 'set ft=fennel' -c 'luafile test/apply_indent.lua' -c 'write' -c 'quit' 2>/dev/null"
                   init-file temp-file)
        ;; Execute nvim command  
        handle (io.popen nvim-cmd)
        _ (handle:close)
        ;; Read the result
        result (read-file temp-file)]
    ;; Clean up temp file
    (os.remove temp-file)
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
