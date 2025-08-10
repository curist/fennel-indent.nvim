# Fennel Indentation Spec

## Scope & unit

* **Indentation only** (no wrapping/spacing changes).
* **Spaces** only; structural unit = **2 spaces**.
* Applies to **Fennel** and Fennel-like Lisps.

## Configuration

* `ALIGN_HEADS`: **set** of head symbols whose list **children may align under the first argument** (e.g., `{"if","and","or","->","->>"}`).
* **Head alignment applies only when the opener line is multi-token** (defined below).

## Terms & coordinates

* **Containers**: list `(...)`, vector `[...]`, table `{...}`, string `"..."` (may be multiline).
* **Columns**: 0-based.
* **opener\_line\_indent**: leading spaces on the line where a container opens.
* **open\_col**: column of the opening delimiter `(` `[` `{` (or the first `"` for strings).
* **head** (lists): first non-space, non-delimiter token after `(` on the opener line, if any.
* **head\_col**: column where the head token starts (0-based).
* **first\_arg\_col** (lists, multi-token opener): on the opener line, the column of the first non-space, non-comment token **after the head and any horizontal whitespace**, if present.
* **inner\_first\_arg\_col**: `first_arg_col` computed for an **inner** list (used by the continuation rule).
* **anchor** (vectors/tables): `open_col + 1`.
* **string\_anchor** (strings): `open_col + 1` (column immediately after the opening `"`).
* **multi-token opener line** (lists): after the head on the **same line**, there exists another non-space, non-comment token before EOL. Otherwise it’s a **single-token opener line**.

## Global precedence rules

1. **Closer-only line** (first code token is `)` `]` or `}`): indent **as if a new child started in the container being closed** —

   * **List `(...)`** → indent to the list **base** (per §List rules, incl. mid-line opener bump; no continuation).
   * **Vector `[...]`** → indent to the **anchor** (`open_col + 1`).
   * **Table `{...}`** → indent to the **anchor** (`open_col + 1`).
2. **Inside a multiline string:** Any line after the first, **including a closing-quote-only line**, indents to the **string\_anchor** (`open_col + 1`).
3. **Inside a table `{…}`:** if the first code token is **not** `}`, indent = **anchor**. A closer-only `}` also indents to the anchor.
4. **Inside a vector `[…]`**: if the first code token is **not** `]`, indent = **anchor**. A closer-only `]` also indents to the anchor.
5. **Inside a list `(…)`**: see **List rules** below.
6. **Comment-only line**: indent **as if** a new child started now in the current container:

   * in `{}` or `[]` → **anchor**
   * in `()` → compute via **List rules** (including continuation)
   * at top level → `0`
7. **Top level**: indent `0`.

> Blank lines: keep as is (no inserted spaces).

## List rules `(…)`

### 1) Base indent

Compute the **base** for top-level children of the current list:

* **Multi-token opener line** (there’s another token after the head on the same line):

  * If **head ∈ `ALIGN_HEADS`** → `base0 = first_arg_col`
  * Else → `base0 = opener_line_indent + 2`

* **Single-token opener line** (head is alone; first child begins on the next line):
  **Ignore head alignment** → `base0 = opener_line_indent + 2`

**Mid-line opener bump (always apply):**

```
# open_col is the '(' of this list
if open_col > opener_line_indent:
  base = max(base0, open_col + 2)
else:
  base = base0
```

*(Closer-only `)` lines use the list **base**, so this bump also affects them.)*

### 2) Continuation under an inner opener

A line is a **continuation** if it continues a child form whose opening `(`:

* is **inside** the current list (any **descendant**, not necessarily a direct child),
* is **at or to the right of the first element** of the current list, and
* was opened on a **previous line**.

**Threshold (“after the first element”):**

```
threshold =
  outer.first_arg_col   # if the outer list’s opener line has a first argument
  else outer.open_col   # single-token opener: no first arg on that line
```

**Eligible inner lists:** list frames that

* are **descendants** of the outer list,
* are currently **open** at the start of this line (on the delimiter stack),
* satisfy `inner.open_line < current_line`, and
* satisfy `inner.open_col ≥ threshold`.

**Candidate selection (deterministic):**

1. Choose the **innermost (deepest)** eligible inner.
2. If tied on depth, pick the **largest `open_line`** (most recent).
3. If still tied (same line), pick the **rightmost**: largest `open_col`.

**Continuation target column:**

```
inner_target_col =
  inner_first_arg_col     # if the inner opener line has a first argument
  else inner.open_col + 2 # single-token inner
```

**Final indent:**

```
indent = max(base, inner_target_col)
```

> Continuation applies only when `inner.open_line < current_line`; same-line wraps are not considered continuation.
> This logic is **independent of `ALIGN_HEADS`**; `ALIGN_HEADS` only affects how `base` is computed in §1.

### 3) No special forms

There are **no macro-specific indentation rules** beyond the optional `ALIGN_HEADS`. Forms like `fn`, `let`, `case`, etc., follow the rules above.

## Comments

* Trailing `; …` on code lines don’t affect indentation.
* **Comment-only** lines follow the **current container**’s child-indent (see Global rule #6).

## Malformed / unclosed code

* Build the delimiter stack by scanning up to (but not including) the target line; treat the current stack as authoritative.
* If you are **inside** an unclosed container, apply that container’s rule (list base, vector/table **anchor**, **string\_anchor**; continuation if eligible).
* A **closer-only** line with **no matching opener** in the stack indents as **top level = 0**.
* An **unclosed multiline string** continues to use **string\_anchor** for all subsequent lines until closed.

## Tokenization assumptions

* Delimiters: `(` `)` `[` `]` `{` `}`.
* Strings: `"..."` with escapes (e.g., `\"`, `\\`), possibly multiline.
* Symbols/identifiers, numbers, keywords (e.g., `:ok`).
* Comments: `;` to end of line.

# Appendix A — Conformance checklist (tests)

Each item: minimal input with **expected formatted result**.

1. **Top-level is 0**

```fennel
foo
(bar)
```

2. **List closer-only line sits at list base**

```fennel
  (foo
    x
    y
    )
```

3. **Tables anchor at `{`+1**

```fennel
{:a 1 :b 2
 :c 3
 :d (f
      g)}
```

4. **Vectors anchor at `[`+1**

```fennel
(let [a 1
      bb 2
      ccc 3]
  body)
```

5. **Comment-only lines align like a child**

```fennel
{:a 1
 ; explain b
 :b 2}
```

```fennel
(and
  ; guard
  (ready? x)
  (not (locked? y)))
```

6. **Inside multiline string**

```fennel
(foo
  "line1
   line2
   line3"
  bar)
```

7. **List base: single-token opener ignores head alignment**

```fennel
(and
  a
  b)
```

8. **List base: multi-token opener uses head alignment (if enabled)**
   `ALIGN_HEADS = {"if"}`

```fennel
(if test
    then-branch
    else-branch)
```

If `ALIGN_HEADS` excludes `if`, then:

```fennel
(if test
  then-branch
  else-branch)
```

9. **Continuation under inner opener (previous line)**

**Input (unformatted):**

```fennel
(if (and (not cond1)
     cond2)
     result)
```

* Expected, with `ALIGN_HEADS={"if","and"}`

```fennel
(if (and (not cond1)
         cond2)
    result)
```

* Expected, with `ALIGN_HEADS={"and"}` only

```fennel
(if (and (not cond1)
         cond2)
  result)
```

10. **Continuation uses `max(base, inner_target_col)`**

Where `inner_target_col = inner_first_arg_col` if present, else `inner_open_col + 2`.


```fennel
(foo (bar
       baz)
  qux)
```

11. **Innermost descendant wins**

```fennel
(if (and (p
          (q
            r))
         s)
  t)
```

12. **Comment-only respects continuation**

```fennel
(if (and (A
           ; note about B
           B)
      C)
  D)
```

13. **Mixed vector/list anchoring**

```fennel
[(:foo 1
   2)
 (:bar 3)]
```

14. **Case/multi-token opener base**

```fennel
(case x
  :a 1
  :b 2)
```

15. **Malformed/unclosed: indent by innermost open frame**

```fennel
(foo
  (bar
    baz
; EOF
```

16. **Closing `}` / `]` sit at anchor**

```fennel
  {:a 1
   :b 2
   }
```

17. **Top-level comment is column 0**

```fennel
; file header
(foo)
```

18. **Table/vector comments anchor**

```fennel
[:a
 ; comment at anchor
 :b]
```

```fennel
(foo
  "x
   y")
```

19. **Vector in binding position: names and values both anchor**

```fennel
(let [name 1
      value
      2]
  body)
```
