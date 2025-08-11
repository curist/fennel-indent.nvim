;; Realistic performance benchmark with nanosecond precision timing
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

(fn benchmark-realistic [file-size]
  "Benchmark with realistic file and better timing"
  (let [content (generate-realistic-file file-size)
        temp-file (os.tmpname)
        ;; Write test file
        file (io.open temp-file :w)]
    (file:write content)
    (file:close)

    ;; Measure performance with better timing
    (let [timing (time-operation 
                   (fn []
                     (let [init-file "test/minimal_init.lua"
                           lua-file "test/apply_indentexpr.lua"
                           nvim-cmd (string.format 
                                      "nvim --headless -u %s %s -c 'set ft=fennel' -c 'luafile %s' -c 'write' -c 'quit' 2>/dev/null"
                                      init-file temp-file lua-file)
                           handle (io.popen nvim-cmd)]
                       (handle:close))))]

      ;; Cleanup
      (os.remove temp-file)

      {:lines file-size
       :duration-ms timing.duration-ms
       :lines-per-ms (/ file-size timing.duration-ms)})))

(fn main []
  "Run realistic benchmark"
  (print "Fennel Indent Realistic Performance Benchmark")
  (print "=============================================")

  (let [sizes [100 500 1000 2000 5000]
        results []]

    (each [_ size (ipairs sizes)]
      (print (.. "Testing " size " lines..."))
      (let [result (benchmark-realistic size)]
        (table.insert results result)
        (print (string.format "  Duration: %.3fms, Lines/ms: %.1f" 
                 result.duration-ms result.lines-per-ms))))

    (print "\nSummary:")
    (print "Lines\tDuration(ms)\tLines/ms")
    (each [_ result (ipairs results)]
      (print (string.format "%d\t%.3f\t\t%.1f" 
               result.lines result.duration-ms result.lines-per-ms)))

    ;; Performance analysis
    (let [largest (. results (length results))]
      (print (string.format "\nPerformance Analysis:"))
      (print (string.format "- Largest test: %d lines in %.3fms" largest.lines largest.duration-ms))
      (if (> largest.lines-per-ms 10)
          (print "✅ Performance: EXCELLENT (>10 lines/ms)")
          (> largest.lines-per-ms 1)
          (print "✅ Performance: GOOD (>1 line/ms)")
          (> largest.lines-per-ms 0.1)
          (print "⚠️  Performance: ACCEPTABLE (>0.1 lines/ms)")
          (print "❌ Performance: POOR (<0.1 lines/ms) - Consider caching")))))

(main)