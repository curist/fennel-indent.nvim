(local assert (require :assert))
(local {: testing} assert)
(local parser (require :scripts.indent-parser))

{:test-golden-01-top-level-zero
 (fn []
   "Golden test 1: Top-level forms have zero indent"
   (testing "top-level forms should have zero indent"
     #(let [input "  foo\n  (bar)"
            expected "foo\n(bar)"
            result (parser.fix-indentation input)]
        (assert.= expected result))))

 :test-golden-02-list-closer-base
 (fn []
   "Golden test 2: List closer-only line sits at list base"
   (testing "list closer should align to base indent"
     #(let [input "(foo\n  x\n  y\n)"  ; closer at opener indent (wrong)
            expected "(foo\n  x\n  y\n  )"  ; closer should be at base (0 + 2 = 2)
            result (parser.fix-indentation input)]
        (assert.= expected result))))

 :test-golden-03-table-anchor
 (fn []
   "Golden test 3: Tables anchor at open_col + 1"
   (testing "table elements should align to anchor with nested list"
     #(let [input "{:a 1 :b 2\n :c 3\n :d (f\ng)}"  ; properly aligned table, misaligned nested list
            expected "{:a 1 :b 2\n :c 3\n :d (f\n      g)}"  ; nested list with mid-line bump: max(3, 4+2)=6
            result (parser.fix-indentation input)]
        (assert.= expected result))))

 :test-golden-04-vector-anchor
 (fn []
   "Golden test 4: Vectors anchor at open_col + 1"
   (testing "vector elements should align to anchor in binding position"
     #(let [input "(let [a 1\nbb 2\nccc 3]\nbody)"  ; misaligned vector elements
            expected "(let [a 1\n      bb 2\n      ccc 3]\n  body)"  ; vector anchor at [ position + 1
            result (parser.fix-indentation input)]
        (assert.= expected result))))

 :test-golden-05-comment-only-lines
 (fn []
   "Golden test 5: Comment-only lines align like a child"
   (testing "comment-only in table aligns to anchor"
     #(let [input "{:a 1\n; explain b\n:b 2}"  ; comment misaligned
            expected "{:a 1\n ; explain b\n :b 2}"  ; comment at anchor like other table elements
            result (parser.fix-indentation input)]
        (assert.= expected result)))

   (testing "comment-only in list follows list base rules"
     #(let [input "(and\n; guard\n(ready? x)\n(not (locked? y)))"  ; comment misaligned
            expected "(and\n  ; guard\n  (ready? x)\n  (not (locked? y)))"  ; comment at list base
            result (parser.fix-indentation input)]
        (assert.= expected result))))

 :test-golden-06-multiline-strings
 (fn []
   "Golden test 6: Inside multiline string uses string_anchor"
   (testing "multiline string lines align to string_anchor"
     #(let [input "(foo\n  \"line1\nline2\nline3\"\n  bar)"  ; string properly positioned, inner lines misaligned
            expected "(foo\n  \"line1\n   line2\n   line3\"\n  bar)"  ; string_anchor = open_col + 1 = 2 + 1 = 3
            result (parser.fix-indentation input)]
        (assert.= expected result))))

 :test-golden-07-single-vs-multi-token-opener
 (fn []
   "Golden test 7: Single-token opener ignores head alignment"
   (testing "single-token opener uses structural indent (ignores ALIGN_HEADS)"
     #(let [input "(and\na\nb)"  ; single-token opener: head alone on line
            expected "(and\n  a\n  b)"  ; structural indent (base + 2), ignores ALIGN_HEADS
            result (parser.fix-indentation input {:and true})]  ; ALIGN_HEADS should be ignored
        (assert.= expected result))))

 :test-golden-08-multi-token-opener-align-heads
 (fn []
   "Golden test 8: Multi-token opener uses head alignment when enabled"
   (testing "multi-token opener with ALIGN_HEADS enabled aligns to first arg"
     #(let [input "(if test\nthen-branch\nelse-branch)"  ; multi-token opener: head + arg on same line
            expected "(if test\n    then-branch\n    else-branch)"  ; align under first arg ("test" at col 3, + 1 = 4)
            result (parser.fix-indentation input {:if true})]
        (assert.= expected result)))

   (testing "multi-token opener without ALIGN_HEADS uses structural indent"
     #(let [input "(if test\nthen-branch\nelse-branch)"
            expected "(if test\n  then-branch\n  else-branch)"  ; structural indent (base + 2)
            result (parser.fix-indentation input {})]  ; no ALIGN_HEADS
        (assert.= expected result))))

 :test-golden-09-continuation-rule
 (fn []
   "Golden test 9: Continuation under inner opener (from spec.md)"
   (testing "continuation with ALIGN_HEADS both if and and"
     #(let [input "(if (and (not cond1)\ncond2)\nresult)"  ; cond2 should continue under inner and, result under if
            expected "(if (and (not cond1)\n         cond2)\n    result)"  ; cond2 at and's first_arg_col, result at if's first_arg_col
            result (parser.fix-indentation input {:if true :and true})]
        (assert.= expected result)))

   (testing "continuation with ALIGN_HEADS and only"
     #(let [input "(if (and (not cond1)\ncond2)\nresult)"
            expected "(if (and (not cond1)\n         cond2)\n  result)"  ; cond2 at and's first_arg_col, result at if's base
            result (parser.fix-indentation input {:and true})]
        (assert.= expected result))))

 :test-golden-10-continuation-max-rule
 (fn []
   "Golden test 10: Continuation uses max(base, inner_target_col)"
   (testing "continuation uses max of base and inner target column"
     #(let [input "(foo (bar\nbaz)\nqux)"  ; baz continues under bar, qux uses list base
            expected "(foo (bar\n       baz)\n  qux)"  ; baz at bar's open_col+2=7, qux at foo's base=2
            result (parser.fix-indentation input)]
        (assert.= expected result))))

 :test-golden-11-comment-continuation
 (fn []
   "Golden test 11: Comment-only respects continuation"
   (testing "comment-only line respects continuation rules"
     #(let [input "(if (and (A\n; note about B\nB)\nC)\nD)"  ; comment should continue under and
            expected "(if (and (A\n           ; note about B\n           B)\n      C)\n  D)"  ; comment follows continuation
            result (parser.fix-indentation input)]
        (assert.= expected result))))

 :test-golden-13-mixed-vector-list-anchoring
 (fn []
   "Golden test 13: Mixed vector/list anchoring"
   (testing "mixed vector with inner lists follows different anchor rules"
     #(let [input "[(:foo 1\n2)\n(:bar 3)]"  ; list inside vector, then vector element
            expected "[(:foo 1\n   2)\n (:bar 3)]"  ; list uses mid-line bump: max(3, 3)=3, vector follows anchor
            result (parser.fix-indentation input)]
        (assert.= expected result))))

 :test-golden-14-case-multi-token-opener
 (fn []
   "Golden test 14: Case/multi-token opener base"
   (testing "case form uses structural base (multi-token opener)"
     #(let [input "(case x\n:a 1\n:b 2)"  ; case is multi-token opener  
            expected "(case x\n  :a 1\n  :b 2)"  ; structural indent since case not in ALIGN_HEADS
            result (parser.fix-indentation input)]
        (assert.= expected result))))

 :test-golden-15-malformed-unclosed
 (fn []
   "Golden test 15: Malformed/unclosed indents by innermost open frame"
   (testing "unclosed code uses innermost frame for indentation"
     #(let [input "(foo\n  (bar\nbaz"  ; bar properly positioned, baz misaligned - should use bar frame
            expected "(foo\n  (bar\n    baz"  ; baz indented under bar frame (innermost)
            result (parser.fix-indentation input)]
        (assert.= expected result))))

 :test-golden-16-table-vector-closers-at-anchor
 (fn []
   "Golden test 16: Closing } / ] sit at anchor"
   (testing "table and vector closers align to anchor position"
     #(let [input "(fn []\n  {:a 1\n:b 2\n})"  ; table inside function, closer misaligned
            expected "(fn []\n  {:a 1\n   :b 2\n   })"  ; closer sits at anchor like other elements
            result (parser.fix-indentation input)]
        (assert.= expected result))))

 :test-golden-17-top-level-comment-zero
 (fn []
   "Golden test 17: Top-level comment is column 0"
   (testing "top-level comments should have zero indent"
     #(let [input "  ; file header\n  (foo)"  ; misaligned top-level comment and form
            expected "; file header\n(foo)"  ; both at column 0
            result (parser.fix-indentation input)]
        (assert.= expected result))))

 :test-golden-18-table-vector-comments-anchor
 (fn []
   "Golden test 18: Table/vector comments anchor"
   (testing "comments in vectors anchor at [+1"
     #(let [input "[:a\n; comment at anchor\n:b]"  ; misaligned comment
            expected "[:a\n ; comment at anchor\n :b]"  ; comment at anchor like other elements
            result (parser.fix-indentation input)]
        (assert.= expected result)))

   (testing "nested string follows string_anchor rule"
     #(let [input "(foo\n  \"x\ny\")"  ; string properly positioned, y misaligned
            expected "(foo\n  \"x\n   y\")"  ; string_anchor = open_col + 1 = 2 + 1 = 3
            result (parser.fix-indentation input)]
        (assert.= expected result))))

 :test-golden-19-vector-binding-anchor
 (fn []
   "Golden test 19: Vector in binding position - names and values both anchor"
   (testing "binding vector with multiline values anchors consistently"
     #(let [input "(let [name 1\nvalue\n2]\nbody)"  ; binding vector with multiline values
            expected "(let [name 1\n      value\n      2]\n  body)"  ; all elements anchor at [+1
            result (parser.fix-indentation input)]
        (assert.= expected result))))}
