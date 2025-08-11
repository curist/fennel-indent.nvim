;; Compilation task: Convert indent-parser.fnl to pure Lua
;; Uses test-runner.com for Fennel environment

(local fennel (require :fennel))

(fn compile-indent-parser []
  "Compile scripts/indent-parser.fnl to lua/fennel-indent/indent-parser.lua"
  (let [input-path "scripts/indent-parser.fnl"
        output-dir "lua/fennel-indent"
        output-path (.. output-dir "/indent-parser.lua")]

    ;; Ensure output directory exists
    (os.execute (.. "mkdir -p " output-dir))

    ;; Read Fennel source
    (let [fennel-code (with-open [file (io.open input-path "r")]
                        (file:read "*a"))]
      (if fennel-code
          ;; Compile to Lua with proper options
          (let [lua-code (fennel.compileString fennel-code)]
            ;; Write compiled Lua
            (with-open [file (io.open output-path "w")]
              (file:write lua-code))
            (print (.. "✓ Compiled " input-path " -> " output-path)))
          (error (.. "Failed to read " input-path))))))

;; Run compilation
(compile-indent-parser)