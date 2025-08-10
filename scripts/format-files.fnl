(fn handle-error [message] (print message) 1)

(fn format-file [file-path ?align-heads]
  "Format a single file in-place. Returns 0 on success, non-zero on error."
  (let [file (io.open file-path "r")
        align-heads (or ?align-heads {})]
    (if (not file)
        (handle-error (.. "Error: Cannot open file " file-path))
        (let [(ok err)
              (pcall
                #(let [content (file:read "*a")]
                   (file:close)
                   (when (not content)
                     (error (.. "Failed to read file: " file-path)))
                   ; Format content
                   (local indent-parser (require :scripts.indent-parser))
                   (let [formatted (indent-parser.fix-indentation content align-heads)]
                     ; Write back if changed
                     (when (not= content formatted)
                       (with-open [f (io.open file-path "w")]
                         (f:write formatted))))))]
          (if ok 0
              (handle-error (.. "Error formatting " file-path ": " (tostring err))))))))

(fn format-files [file-paths ?align-heads]
  "Format multiple files. Returns 0 if all succeed, non-zero if any fail."
  (accumulate [exit-code 0 _ file-path (ipairs file-paths)]
    (let [file-exit-code (format-file file-path ?align-heads)]
      (if (= exit-code 0) file-exit-code exit-code))))

(fn main [args]
  "Main CLI entry point"
  (if (= (length args) 0)
      (handle-error "Usage: fennel scripts/format-files.fnl <file1.fnl> [file2.fnl ...]")
      (let [align-heads {:if true :and true :or true :.. true
                         :-> true :->> true :-?> true :-?>> true}]
        (format-files args align-heads))))

; If running as script (not being required), run main
; Compare script name from arg[0] with current source file name
(if (= (. arg 0) (. (debug.getinfo 1 :S) :short_src))
    (os.exit (main arg))
    ; Otherwise, export functions for module use
    {: format-file : format-files : main})
