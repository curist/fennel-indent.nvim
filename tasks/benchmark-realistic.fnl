;; Realistic benchmark testing actual Vim/Neovim gg=G vs gqG behavior
(local rb (require :redbean))

(fn generate-realistic-file [lines]
  "Generate a realistic Fennel file with mixed structures"
  (var content "")
  (for [i 1 lines]
    (let [;; Create varying nesting patterns
          mod-3 (% i 3)
          mod-5 (% i 5)
          line (if (= mod-3 0) 
                   (.. "(let [x" i " " i "\n      y" i " (* x" i " 2)]\n  (+ x" i " y" i "))\n")
                   (= mod-5 0)
                   (.. "{:key" i " :value" i "\n :nested {:inner" i " " i "\n          :deep {:very-deep " i "}}}\n")
                   (= (% i 7) 0)
                   (.. "[" i " " (* i 2) "\n " (* i 3) " " (* i 4) "]\n")
                   ;; Regular function calls  
                   (.. "(function-" i "\n  arg" i "\n  arg" (* i 2) ")\n"))]
      (set content (.. content line))))
  content)

(fn time-operation [operation]
  "Time an operation with nanosecond precision using redbean clock_gettime"
  (let [(start-sec start-nano) (rb.unix.clock_gettime rb.unix.CLOCK_MONOTONIC)
        result (operation)
        (end-sec end-nano) (rb.unix.clock_gettime rb.unix.CLOCK_MONOTONIC)
        ;; Calculate duration in nanoseconds
        duration-sec (- end-sec start-sec)
        duration-nano (- end-nano start-nano)
        total-nano (+ (* duration-sec 1000000000) duration-nano)
        duration-ms (/ total-nano 1000000)]
    {:result result
     :duration-ms duration-ms}))

(fn benchmark-gg-equal-g [file-size]
  "Benchmark actual gg=G behavior (indentexpr)"
  (let [content (generate-realistic-file file-size)
        temp-file (os.tmpname)
        ;; Write test file
        file (io.open temp-file :w)]
    (file:write content)
    (file:close)

    ;; Measure gg=G performance 
    (let [timing (time-operation 
                   (fn []
                     (let [init-file "test/minimal_init.lua"
                           nvim-cmd (string.format 
                                      "nvim --headless -u %s %s -c 'set ft=fennel' -c 'normal! gg=G' -c 'write' -c 'quit' 2>/dev/null"
                                      init-file temp-file)
                           handle (io.popen nvim-cmd)]
                       (handle:close))))]

      ;; Cleanup
      (os.remove temp-file)

      {:method "gg=G (indentexpr)"
       :lines file-size
       :duration-ms timing.duration-ms
       :lines-per-ms (/ file-size timing.duration-ms)})))

(fn benchmark-gq-g [file-size]
  "Benchmark actual gqG behavior (formatexpr)"
  (let [content (generate-realistic-file file-size)
        temp-file (os.tmpname)
        ;; Write test file
        file (io.open temp-file :w)]
    (file:write content)
    (file:close)

    ;; Measure gqG performance
    (let [timing (time-operation 
                   (fn []
                     (let [init-file "test/minimal_init.lua"
                           nvim-cmd (string.format 
                                      "nvim --headless -u %s %s -c 'set ft=fennel' -c 'normal! gqG' -c 'write' -c 'quit' 2>/dev/null"
                                      init-file temp-file)
                           handle (io.popen nvim-cmd)]
                       (handle:close))))]

      ;; Cleanup
      (os.remove temp-file)

      {:method "gqG (formatexpr)"
       :lines file-size
       :duration-ms timing.duration-ms
       :lines-per-ms (/ file-size timing.duration-ms)})))

(fn benchmark-single-pass [file-size]
  "Benchmark our fix-indentation function directly (theoretical best case)"
  (let [content (generate-realistic-file file-size)
        indent-parser (require :scripts.indent-parser)]
    
    (let [timing (time-operation 
                   (fn []
                     (indent-parser.fix-indentation content {})))]

      {:method "Single-pass (fix-indentation)"
       :lines file-size
       :duration-ms timing.duration-ms
       :lines-per-ms (/ file-size timing.duration-ms)})))

(fn main []
  "Run realistic benchmark comparing all approaches"
  (print "Fennel Indent: Real-world Performance Comparison")
  (print "===============================================")

  (let [sizes [100 500 1000 2000 5000]
        all-results []]

    (each [_ size (ipairs sizes)]
      (print (.. "\n📏 Testing " size " lines:"))
      
      ;; Test gg=G (indentexpr)
      (print "  Testing gg=G (indentexpr)...")
      (let [gg-result (benchmark-gg-equal-g size)]
        (table.insert all-results gg-result)
        (print (string.format "    Duration: %.3fms, Lines/ms: %.1f" 
               gg-result.duration-ms gg-result.lines-per-ms)))
      
      ;; Test gqG (formatexpr) 
      (print "  Testing gqG (formatexpr)...")
      (let [gq-result (benchmark-gq-g size)]
        (table.insert all-results gq-result)
        (print (string.format "    Duration: %.3fms, Lines/ms: %.1f" 
               gq-result.duration-ms gq-result.lines-per-ms)))
      
      ;; Test single-pass (theoretical best)
      (print "  Testing single-pass (fix-indentation)...")
      (let [sp-result (benchmark-single-pass size)]
        (table.insert all-results sp-result)
        (print (string.format "    Duration: %.3fms, Lines/ms: %.1f" 
               sp-result.duration-ms sp-result.lines-per-ms))))

    ;; Summary table
    (print "\n📊 Performance Summary:")
    (print "Lines\tMethod\t\t\t\tDuration(ms)\tLines/ms")
    (print "-----\t------\t\t\t\t-----------\t--------")
    (each [_ result (ipairs all-results)]
      (print (string.format "%d\t%-20s\t\t%.3f\t\t%.1f" 
               result.lines result.method result.duration-ms result.lines-per-ms)))

    ;; Analysis
    (print "\n🔍 Analysis:")
    (print "- gg=G: Uses indentexpr line-by-line (cached, but still O(n²) scaling)")
    (print "- gqG: Uses formatexpr range-based (should be much faster)")
    (print "- Single-pass: Direct fix-indentation call (theoretical maximum)")
    (print "\n💡 Recommendation: Use 'gqG' instead of 'gg=G' for whole-file formatting")))

(main)