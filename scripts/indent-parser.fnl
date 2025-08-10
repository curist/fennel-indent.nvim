;; Fennel indentation fixer following spec.md exactly
;; Simple, consistent, optional semantic alignment

(fn get-leading-spaces [line]
  "Get count of leading spaces in line"
  (let [spaces (string.match line "^( *)")]
    (length (or spaces ""))))

(fn line-starts-with-closer? [line]
  "Check if line starts with ), ], or }"
  (let [t (string.gsub line "^%s*" "")]
    (let [c (and (> (length t) 0) (string.sub t 1 1))]
      (or (= c ")") (= c "]") (= c "}")))))

(fn comment-only-line? [line]
  "Check if line contains only whitespace and/or comment"
  (let [trimmed (string.gsub line "^%s*" "")]
    (or (= trimmed "")
        (string.match trimmed "^;"))))

(fn pop-matching! [stack closer]
  "Pop the nearest frame of matching type for the closer"
  (let [want (case closer
               ")" :list
               "]" :vector
               "}" :table)]
    (when want
      (var i (length stack))
      (while (and (> i 0) (not= (. (. stack i) :type) want))
        (set i (- i 1)))
      (when (> i 0) (table.remove stack i)))))

(fn tokenize-line [line line-num frame-stack]
  "Tokenize line tracking delimiters and strings, updating frame stack"
  (let [len (length line)
        current-indent (get-leading-spaces line)]
    (var i 1)
    (var in-string false)
    (var escape-next false)

    ; Find if we're starting inside a multiline string
    (when (and (> (length frame-stack) 0)
               (= (. (. frame-stack (length frame-stack)) :type) :string))
      (set in-string true))

    (while (<= i len)
      (let [char (string.sub line i i)]
        (if escape-next
            (set escape-next false)
            in-string
            (if (= char "\\")
                (set escape-next true)
                (= char "\"")
                (do 
                  (set in-string false)
                  ; Pop string frame
                  (when (and (> (length frame-stack) 0)
                             (= (. (. frame-stack (length frame-stack)) :type) :string))
                    (table.remove frame-stack))))
            (= char ";")
            ; Comment to end of line - stop processing
            (set i (+ len 1))

            ; Handle new frames with parent pointer tracking
            (let [parent (when (> (length frame-stack) 0)
                           (. frame-stack (length frame-stack)))]
              (if
                (= char "\"")
                (do 
                  (set in-string true)
                  ; Push string frame
                  (table.insert frame-stack 
                    {:type :string
                     :indent current-indent
                     :open_col (- i 1)
                     :open_line line-num
                     :parent parent}))
                (= char "(")
                (let [frame {:type :list
                             :indent current-indent
                             :open_col (- i 1)
                             :open_line line-num
                             :parent parent}]
                  ; Look for head symbol on same line
                  (var j (+ i 1))
                  (while (and (<= j len) (string.match (string.sub line j j) "%s")) 
                    (set j (+ j 1)))
                  (when (<= j len)
                    (let [head-start j]
                      (while (and (<= j len)
                                  (not (string.match (string.sub line j j) "[%s()%[%]{};\"]")))
                        (set j (+ j 1)))
                      (when (> j head-start)
                        (set frame.head_symbol (string.sub line head-start (- j 1)))
                        (set frame.head_col (- head-start 1))
                        ; Look for first argument after head
                        (while (and (<= j len) (string.match (string.sub line j j) "%s"))
                          (set j (+ j 1)))
                        (when (and (<= j len) (not (string.match (string.sub line j j) "[;]")))
                          (set frame.first_arg_col (- j 1))))))
                  (table.insert frame-stack frame))
                (= char "[")
                (table.insert frame-stack 
                  {:type :vector
                   :indent current-indent
                   :open_col (- i 1)
                   :open_line line-num
                   :parent parent})
                (= char "{")
                (table.insert frame-stack 
                  {:type :table
                   :indent current-indent
                   :open_col (- i 1)
                   :open_line line-num
                   :parent parent})
                (or (= char ")") (= char "]") (= char "}"))
                ; Pop matching frame by type
                (pop-matching! frame-stack char))))
        (set i (+ i 1))))))

(fn is-descendant? [f outer]
  "Check if frame f is a descendant of outer frame"
  (var p f.parent)
  (while p
    (when (= p outer) (lua "return true"))
    (set p p.parent))
  false)

(fn find-innermost-opener [stack current-line-num]
  "Find innermost list opener that qualifies for continuation rule"
  (when (> (length stack) 0)
    ; outer is the topmost list on stack
    (var outer nil)
    (for [i (length stack) 1 -1]
      (when (= (. (. stack i) :type) :list) 
        (set outer (. stack i)) 
        (lua "break")))
    (when outer
      (let [threshold (or outer.head_col outer.open_col)]
        (for [i (length stack) 1 -1]
          (let [f (. stack i)]
            (when (and (= f.type :list)
                       (not= f outer)
                       (is-descendant? f outer)                 ; descendant check
                       (< f.open_line current-line-num)         ; previous line
                       (> f.open_col threshold))                ; after first elem
              (lua "return f"))))))))

(fn calculate-indent [line line-num frame-stack align-heads]
  "Calculate target indent following spec.md line rules in precedence order"
  (let [top-frame (when (> (length frame-stack) 0)
                    (. frame-stack (length frame-stack)))]
    (if
      ; 1. Line starts with closer → indent as if new child in that container
      (line-starts-with-closer? line)
      (let [first (string.sub (string.gsub line "^%s*" "") 1 1)
            want (case first ")" :list "]" :vector "}" :table)]
        (var indent 0)
        (when want
          (for [i (length frame-stack) 1 -1]
            (let [frame (. frame-stack i)]
              (when (= frame.type want)
                (set indent 
                  (if (= want :list)
                      ; List: use base indent (opener_line_indent + 2, with mid-line bump)
                      (let [base0 (+ frame.indent 2)
                            base (if (> frame.open_col frame.indent)
                                     (math.max base0 (+ frame.open_col 2))
                                     base0)]
                        base)
                      ; Vector/table: use anchor (open_col + 1)
                      (+ frame.open_col 1)))
                (lua "break")))))
        indent)

      ; 2. Inside string → string_anchor (open_col + 1)
      (and top-frame (= top-frame.type :string))
      (+ top-frame.open_col 1)

      ; 3. Inside table → anchor (open_col + 1)
      (and top-frame (= top-frame.type :table))
      (+ top-frame.open_col 1)

      ; 4. Inside vector → anchor (open_col + 1)  
      (and top-frame (= top-frame.type :vector))
      (+ top-frame.open_col 1)

      ; 5. Inside list → base + continuation rule
      (and top-frame (= top-frame.type :list))
      (let [base0 (if (and top-frame.head_symbol 
                           top-frame.first_arg_col
                           (. align-heads top-frame.head_symbol))
                      top-frame.first_arg_col
                      (+ top-frame.indent 2))
            ; Apply mid-line bump rule
            base (if (> top-frame.open_col top-frame.indent)
                     (math.max base0 (+ top-frame.open_col 2))
                     base0)
            inner-opener (find-innermost-opener frame-stack line-num)
            continuation-col (if inner-opener
                                 (or inner-opener.first_arg_col (+ inner-opener.open_col 2))
                                 base)]
        (math.max base continuation-col))

      ; 6. Comment-only line → same as if child started here
      (comment-only-line? line)
      (if (not top-frame)
          0
          (= top-frame.type :table)
          (+ top-frame.open_col 1)
          (= top-frame.type :vector)
          (+ top-frame.open_col 1)
          (= top-frame.type :list)
          (let [base0 (if (and top-frame.head_symbol 
                               top-frame.first_arg_col
                               (. align-heads top-frame.head_symbol))
                          top-frame.first_arg_col
                          (+ top-frame.indent 2))
                ; Apply mid-line bump rule for comment-only lines too
                base (if (> top-frame.open_col top-frame.indent)
                         (math.max base0 (+ top-frame.open_col 2))
                         base0)
                inner-opener (find-innermost-opener frame-stack line-num)
                continuation-col (if inner-opener
                                     (or inner-opener.first_arg_col (+ inner-opener.open_col 2))
                                     base)]
            (math.max base continuation-col))
          (= top-frame.type :string)
          (+ top-frame.open_col 1)
          0)

      ; 7. Top-level → 0
      0)))

(fn fix-indentation [input ?align-heads]
  "Fix indentation following spec.md rules exactly"
  (let [lines (icollect [line (string.gmatch (.. input "\n") "([^\n]*)\n")] line)
        align-heads (or ?align-heads {})
        frame-stack []
        result-lines []]

    ; Pre-scan: check for lines exceeding 300 characters
    (each [_ line (ipairs lines)]
      (when (> (length line) 300)
        (lua "return input")))

    ; Process each line
    (each [line-num line (ipairs lines)]
      (let [trimmed (string.gsub line "^%s*" "")]
        (if (= trimmed "")
            ; Preserve blank lines without spaces
            (table.insert result-lines "")
            ; Calculate indent and format
            (let [target-indent (calculate-indent line line-num frame-stack align-heads)
                  formatted-line (.. (string.rep " " target-indent) trimmed)]
              ; Update frame stack based on the formatted line's content
              (tokenize-line formatted-line line-num frame-stack)
              (table.insert result-lines formatted-line)))))

    (table.concat result-lines "\n")))

{: fix-indentation : tokenize-line : calculate-indent}
