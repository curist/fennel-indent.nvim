# Fennel Indentation Spec

## Scope
- **Indentation only** (no wrapping/spacing)
- **2-space** structural indent
- Applies to **Fennel** and Fennel-like Lisps

## Configuration
- `ALIGN_HEADS`: set of symbols that align children under first argument (e.g., `{"if","and","->"}`)
- Only applies when the opener line has multiple tokens

## Basic Terms
- **Containers**: `(...)` `[...]` `{...}` `"..."`
- **Opener column**: opening delimiter position (0-based column)
- **Opener line indent**: leading spaces count on the line containing the opener
- **Anchor**: `opener_column + 1` (for vectors, tables, strings)
- **Head**: first symbol after `(` on same line
- **First arg**: first token after head on same line
- **First arg column**: starting position of first argument (0-based)

## Indentation Rules (by precedence)

### 1. Closers `)` `]` `}`
Indent as if starting a new child in that container:
- **Lists**: use list base (see below)
- **Vectors/tables**: use anchor
- **Unmatched closer**: column 0

### 2. Inside strings
All lines after opening quote: **anchor**

### 3. Inside vectors `[...]` or tables `{...}`
All non-closing content: **anchor**
- Keys and values both start at the anchor position
- Multiline values follow their own container's indentation rules (not table anchor)

### 4. Inside lists `(...)`
**Base calculation:**
- Single-token opener (head alone): `opener_line_indent + 2`
- Multi-token opener:
  - If `head ∈ ALIGN_HEADS`: `first_arg_column`
  - Else: `opener_line_indent + 2`
- **Mid-line bump**: if `opener_column > opener_line_indent`, use `max(base, opener_column + 2)`

**Continuation rule:**
If there's an inner `(` opened on a previous line that's:
- Inside current list
- At/right of current list's first element (column ≥ current_list_first_element_column)
- Still unclosed

Then use `max(base, inner_target)` where `inner_target` is the inner list's calculated indentation.

### 5. Comment-only lines
Treated as if starting new content in current container.

### 6. Top-level
Column 0.

### 7. Blank lines
Unchanged.

## Malformed Code
Use the innermost unclosed container's rule.

---

# Test Cases

### 1. Top-level
```fennel
foo
(bar)
; comment
```

### 2. List base (structural)
```fennel
(foo
  x
  y
  )
```

### 3. List base (aligned) - `ALIGN_HEADS={"if"}`
```fennel
(if test        ; opener_column=0, head="if" at col 1, first_arg="test" at col 4
    then-branch ; indented to first_arg_column=4 (aligned)
    else-branch
    )

; Contrast: if "if" NOT in ALIGN_HEADS (structural only):
(if test        
  then-branch   ; would be indented to opener_line_indent + 2 = 2
  else-branch
  )
```

### 4. Single vs multi-token
```fennel
(and          ; opener_column=0, opener_line_indent=0, only head on line
  a           ; structural indent: opener_line_indent + 2 = 2
  b)

(if x         ; opener_column=0, head="if", first_arg="x" at col 4
  y           ; if ∈ ALIGN_HEADS: first_arg_column = 4, but no mid-line bump needed
  z)

(nested       ; opener_column=0, opener_line_indent=0, top-level
  content)    ; structural: opener_line_indent + 2 = 2
```

### 5. Vectors and tables
```fennel
(let [a 1
      bb 2
      ccc 3]
  body)

{:a 1 :b 2
 :c 3
 :d (nested
      call)
 }
```

### 6. Strings
```fennel
(foo
  "line1
   line2
   line3"
  bar)
```

### 7. Comments
```fennel
{:a 1
 ; table comment
 :b 2}

(and
  ; list comment  
  (ready? x)
  (done? y))
```

### 8. Continuation - `ALIGN_HEADS={"if","and"}`
```fennel
(if (and (not cond1)  ; outer 'if' opener at col 0, inner 'and' opener at col 4
         cond2)       ; continues under 'and' at col 9 (first arg of 'and')
    result)           ; back to 'if' base at col 4 (first arg of 'if')
```

### 9. Complex continuation
```fennel
(foo (bar
       baz)  ; under 'bar'
  qux)       ; back to 'foo' base
```

### 10. Nested continuation
```fennel
(if (and (p
          (q    ; deepest wins
            r))
         s)
  t)
```

### 11. Mixed containers
```fennel
(let [{:name        ; table starts at list anchor (opener_line_indent + 2 = 2)
       "John"       ; value aligns at table anchor (opener_column + 1 = 7)
       :age 30}     ; back to table anchor
      [x y z]]      ; vector at list anchor
  {:result (+ x y)  ; table at list anchor, value follows list rules
   :items [a        ; vector value at table anchor
           b        ; vector content at vector anchor  
           c]})     ; back to table anchor for closing
```

### 12. Malformed/unclosed
```fennel
(foo
  (bar
    baz    ; uses 'bar' frame
; EOF - incomplete
```
