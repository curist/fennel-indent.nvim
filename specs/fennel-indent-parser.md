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
- **Opener**: opening delimiter position (0-based column)
- **Anchor**: `opener + 1` (for vectors, tables, strings)
- **Head**: first symbol after `(` on same line
- **First arg**: first token after head on same line

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

### 4. Inside lists `(...)`
**Base calculation:**
- Single-token opener (head alone): `opener_line_indent + 2`
- Multi-token opener:
  - If `head ∈ ALIGN_HEADS`: align under first arg
  - Else: `opener_line_indent + 2`
- **Mid-line bump**: if opener is indented, use `max(base, opener + 2)`

**Continuation rule:**
If there's an inner `(` opened on a previous line that's:
- Inside current list
- At/right of current list's first element
- Still unclosed

Then use `max(base, inner_target)` where `inner_target` is the inner list's alignment.

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
(if test
    then-branch
    else-branch
    )
```

### 4. Single vs multi-token
```fennel
(and
  a    ; single-token: structural
  b)

(if x    ; multi-token: can use ALIGN_HEADS
  y
  z)
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

### 8. Continuation
```fennel
(if (and (not cond1)
         cond2)    ; continues under 'and'
    result)        ; back to 'if' base
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
[(:foo 1
   2)    ; list in vector
 (:bar 3) ; back to vector anchor
 ]
```

### 12. Malformed/unclosed
```fennel
(foo
  (bar
    baz    ; uses 'bar' frame
; EOF - incomplete
```
