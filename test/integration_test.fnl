(local assert (require :assert))
(local {: testing} assert)
(local helper (require :test.integration_helper))

{:test-integration-top-level-zero
 (fn []
   "Integration: Top-level forms have zero indent via indentexpr"
   (testing "headless nvim indentexpr matches fix-indentation for top-level"
     #(let [expected (helper.read-expected "top-level-zero")
            result (helper.test-indentexpr-with-nvim "top-level-zero")]
        (assert.= expected result))))

 :test-integration-list-closer-base  
 (fn []
   "Integration: List closer-only line sits at list base via indentexpr"
   (testing "headless nvim indentexpr matches fix-indentation for list closer"
     #(let [expected (helper.read-expected "list-closer-base")
            result (helper.test-indentexpr-with-nvim "list-closer-base")]
        (assert.= expected result))))

 :test-integration-table-anchor
 (fn []
   "Integration: Tables anchor at open_col + 1 via indentexpr"
   (testing "headless nvim indentexpr matches fix-indentation for table anchor"
     #(let [expected (helper.read-expected "table-anchor")
            result (helper.test-indentexpr-with-nvim "table-anchor")]
        (assert.= expected result))))

 ;; formatexpr integration tests
 :test-formatexpr-top-level-zero
 (fn []
   "Integration: formatexpr correctly formats top-level forms"
   (testing "formatexpr handles top-level zero indentation via gq"
     #(let [expected (helper.read-expected "top-level-zero") 
            result (helper.test-formatexpr-with-nvim "top-level-zero")]
        (assert.= expected result))))

 :test-formatexpr-list-closer-base
 (fn []
   "Integration: formatexpr correctly formats list closers" 
   (testing "formatexpr handles list closer base alignment via gq"
     #(let [expected (helper.read-expected "list-closer-base")
            result (helper.test-formatexpr-with-nvim "list-closer-base")]
        (assert.= expected result))))

 :test-formatexpr-table-anchor
 (fn []
   "Integration: formatexpr correctly formats table anchoring"
   (testing "formatexpr handles table anchor alignment via gq" 
     #(let [expected (helper.read-expected "table-anchor")
            result (helper.test-formatexpr-with-nvim "table-anchor")]
        (assert.= expected result))))}