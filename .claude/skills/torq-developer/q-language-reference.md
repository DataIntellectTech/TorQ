# q/kdb+ Language Reference — Edge Cases and Developer Traps

## 1. Type System

### Type Code Table

| Type# | Char | Name | Size | Null | Infinity | Example |
|---|---|---|---|---|---|---|
| -1h | b | boolean | 1 | `0b` | — | `1b` |
| -4h | x | byte | 1 | `0x00` | — | `0xff` |
| -5h | h | short | 2 | `0Nh` | `0Wh` | `42h` |
| -6h | i | int | 4 | `0Ni` | `0Wi` | `42i` |
| -7h | j | long | 8 | `0Nj` / `0N` | `0Wj` / `0W` | `42` |
| -8h | e | real | 4 | `0Ne` | `0We` | `1.5e` |
| -9h | f | float | 8 | `0n` | `0w` | `1.5` |
| -10h | c | char | 1 | `" "` | — | `"a"` |
| -11h | s | symbol | * | `` ` `` | — | `` `sym `` |
| -12h | p | timestamp | 8 | `0Np` | `0Wp` | `2024.01.01D00:00:00` |
| -13h | m | month | 4 | `0Nm` | `0Wm` | `2024.01m` |
| -14h | d | date | 4 | `0Nd` | `0Wd` | `2024.01.01` |
| -15h | z | datetime | 8 | `0Nz` | `0Wz` | `2024.01.01T00:00:00` |
| -16h | n | timespan | 8 | `0Nn` | `0Wn` | `00:01:00.000000000` |
| -17h | u | minute | 4 | `0Nu` | `0Wu` | `00:01` |
| -18h | v | second | 4 | `0Nv` | `0Wv` | `00:01:00` |
| -19h | t | time | 4 | `0Nt` | `0Wt` | `00:01:00.000` |
| 0h | — | mixed list | — | — | — | `(1;2.0;"a")` |
| 10h | — | char vector (string) | — | — | — | `"hello"` |
| 11h | — | symbol list | — | — | — | `` `a`b`c `` |
| 20-76h | — | enumeration | — | — | — | `` `sym$`x `` |
| 98h | — | table | — | — | — | `([]a:1 2 3)` |
| 99h | — | dictionary | — | — | — | `` `a`b!1 2 `` |
| 100h+ | — | function/lambda | — | — | — | `{x+y}` |

### Type Detection Traps

**Trap 1 — Atom vs vector type codes:**
```q
q)type 42        // -7h  (negative = atom)
-7h
q)type enlist 42 // 7h   (positive = vector)
7h
q)type 42 43     // 7h   (vector)
7h
```

**Trap 2 — `type` on empty lists:**
```q
q)type ()        // 0h  (generic empty list)
0h
q)type `int$()   // 6h  (typed empty list)
6h
q)count `int$()  // 0   (but has a type!)
0
```

**Trap 3 — Mixed list promotion:**
```q
q)type 1 2 3     // 7h  (long vector, NOT mixed)
7h
q)type 1 2 3.0   // 9h  (promoted to float — 3.0 causes promotion)
9h
q)type (1;2.0)   // 0h  (mixed: int and float don't auto-promote in parens)
0h
```

**Trap 4 — Char vector vs list of strings:**
```q
q)type "abc"             // 10h (string = char vector)
10h
q)type ("a";"b";"c")     // 10h — a list of char atoms collapses to a string
10h
q)type ("ab";"cd")       // 0h  (list of strings)
0h
```

**Trap 5 — Symbol interning:**
Symbols are interned — once created they persist in the symbol table for the process lifetime. Never create symbols dynamically from high-cardinality data (e.g., UUIDs). Use strings or enumerations instead.
```q
// DANGEROUS: creates millions of permanent symbols
sym:`$string each til 1000000

// SAFE: use string
str:string each til 1000000
```

**Trap 6 — Enumeration types:**
An enumerated column has type 20h-76h (depends on which domain). After loading from disk, sym columns are enums. `value enum_col` gives symbol list. `enum_col~`mysym` works correctly.

**Trap 7 — Null comparisons:**
```q
q)0N = 0N    // 1b — unlike SQL, same-type nulls compare equal
1b
q)0N < 5     // 1b — nulls sort lowest, so `where x<5` also returns nulls
1b
q)null 0N    // 1b  (use null to test explicitly)
1b
q)null each (0N;1;0Ni;0n)  // 1011b
```

### Casting

```q
// Numeric upcast (safe)
`float$42       // 42f
`long$42h       // 42

// Narrowing casts (KDB-X 5.0 saturates to infinity; check behaviour on your version)
`int$2147483648 // 0Wi
`short$40000    // 0Wh
`long$3.7       // 4 (float to integral rounds, it does not truncate)

// String to symbol
`$"hello"       // `hello

// Type code cast (positive type codes only; -7h$3.7 signals 'type)
9h$3            // 3f
7h$3.7          // 4

// Date arithmetic: dates are ints from 2000.01.01
`int$2000.01.01  // 0
`int$2000.01.02  // 1
2000.01.01+1     // 2000.01.02
```

---

## 2. Iterators and Adverbs — Edge Cases

### Each (`'`)

```q
q)f:{x+1}
q)f each 1 2 3     // 2 3 4 (atomic, same as f 1 2 3 for atomic f)
q)f'[1 2 3]        // 2 3 4 (adverb form)

// Each on a binary function requires two matching-length lists
q){x+y}'[1 2 3; 10 20 30]  // 11 22 33

// Each-right and Each-left for cross-application
q)1 2 3 +/: 10 20  // (11 12 13; 21 22 23) — add each right to each left list
q)1 2 3 +\: 10 20  // (11 21; 12 22; 13 23) — each left applied to each right
```

**Trap — each on atomic functions is redundant but harmless:**
```q
q)neg each 1 2 3   // -1 -2 -3 (same as neg 1 2 3)
```

**Trap — each on string-atomic functions:**
```q
q)upper "hello"                    // "HELLO" (operates on entire string)
q)upper each "hello"               // "HELLO" (same — upper is string-atomic)
q)upper each ("hello";"world")     // ("HELLO";"WORLD") (list of strings)
```

### Over (`/`) and Scan (`\`)

```q
// Over (fold/reduce)
q)0 +/ 1 2 3 4 5   // 15
q)(+/) 1 2 3 4 5   // 15 (same, unary projection)

// Scan (all intermediate results)
q)0 +\ 1 2 3 4 5   // 1 3 6 10 15 (the seed is not included)
q)(+\) 1 2 3 4 5   // 1 3 6 10 15  (no seed — starts from first element)

// Convergence form (iterate until stable)
q){x*x}/ 0.5       // 0 (converges to 0)

// N-times form
q)2 {x*2}/ 1       // 4 (apply 2 times: 1→2→4)

// While form: apply while the condition is true
q){x<1000} {x*2}/ 1  // 1024
```

**Trap — over with seed vs without:**
```q
q)(+/) 1 2 3    // 6  (no seed: uses first element as seed)
q)0 +/ 1 2 3   // 6  (explicit seed)
q)1 +/ 1 2 3   // 7  (seed=1, result is 1+1+2+3=7)
```

**Trap — scan does NOT include the seed:**
```q
q)0 +\ 1 2 3   // 1 3 6
q)1 +\ 1 2 3   // 2 4 7
q)(+\) 1 2 3   // 1 3 6
```

### Each-Prior (`':`)

```q
q)(-':) 1 3 6 10   // 1 2 3 4  (differences, first element treated as 0 prior)
q)1 -': 1 3 6 10   // 0 2 3 4  (explicit prior seed of 1)
```

### Parallel Each (`peach`)

```q
// Requires slave threads: q myfile.q -s 4
q){system"sleep 1";x} peach 1 2 3 4  // runs in parallel on 4 threads
```

**Trap — peach cannot write globals:**
```q
// Secondary threads (-s N) can read globals but not set them
q){g::x} peach 1 2      // 'noupdate
// Return values instead and assign in the main thread
```

---

## 3. IPC Edge Cases

### Handle Arithmetic

```q
h:hopen `:host:5000        // positive handle (sync)
neg[h]                     // negative handle (async)
h (`.proc.procname;`)      // sync call
neg[h] (`.proc.procname;`) // async (fire and forget)
neg[h] (::)                // flush async queue (forces send)
h (::)                     // sync barrier (ensures prior async messages processed)
```

**Trap — deferred sync pattern:**
```q
// Server: gateway sends async, then blocks waiting for result
neg[h] (`.gw.asyncexec; query; `rdb)
result:h[]    // block on handle until server sends back result
// This is "deferred synchronous" — server can process query async
```

**Trap — connection limit:**
- Pre-4.1t (2023.09.15): max 1022 connections. Exceeding gives `'conn` error.
- Post-4.1t: limit removed.

**Trap — interrupted sync request:**
- If a process receives `kill -s INT` while a sync query is blocking, subsequent IPC attempts on that handle fail with "Bad file descriptor".
- Always `hclose` the handle and reopen.

**Trap — message ordering:**
- All messages on a single handle are sequential.
- A sync call guarantees all prior async messages on that handle have been sent.
- To explicitly flush: `neg[h] (::)` then `h (::)`.

**Trap — compression:**
- Automatic for messages >2000 bytes when not on localhost/UDS, and compressed size <50% of original.
- Do NOT rely on enumerations in IPC — they are automatically converted to values before transmission.

**Trap — `hopen` timeout:**
- Default `hopen` blocks forever.
- TorQ uses `(hopen x; timeout)` form with `.servers.HOPENTIMEOUT` (default 2000ms).

**Trap — negative handle send fails silently:**
```q
// neg[h] sends asynchronously — if it fails, you get no error here
neg[h] "invalid_expression"  // no error raised in caller process
// The receiving process gets an error; use .z.ps error handling on server side
```

### Serialization

```q
-8! x   // serialize (convert to bytes)
-9! x   // deserialize (bytes to q value)
// For binary (kdb+ IPC) frames; JSON over WebSockets is sent as a plain string
```

---

## 4. Error Handling Scoping

### Basic Trap

```q
// Two-arg trap: function and error handler
@[f; x; handler]              // unary trap: evaluates f[x]
.[f; (x;y); handler]          // multi-argument trap

// Error handler receives error string
@[{1+`a}; ::; {0N! "caught: ",x}]  // prints "caught: type"

// Return default on error
result:@[{1+`a}; ::; {0N}]    // returns 0N (long null) on error
```

**Trap — traps do not roll back:**
```q
// Global assignments made before the error are kept
a:1;
@[{a::2; 1+`a}; ::; {x}];
a  // 2 — nothing is rolled back
@[{a::2; 1+`a}; ::; {a::3}];
a  // 3 — the handler ran after the body's a::2
```

**Trap — nested errors and stack:**
```q
// Error signals propagate up the call stack
// Only the innermost @[...] catches the error
// Outer traps don't see errors caught by inner traps
f:{@[{1+`a};::;{"inner: ",x}]}
@[f;::;{"outer: ",x}]  // returns "inner: type" — outer trap never fires
```

**Trap — signal with `'`:**
```q
'`myerror         // signal symbol error
'"my error string" // signal string error
// To re-signal after catching:
@[dangerousfn; arg; {'x}]  // re-raise any caught error
```

**Trap — exit and .z.exit:**
```q
.z.exit:{[exitcode] .lg.o[`exit;"process exiting with code ",string exitcode]}
exit 0   // clean exit; triggers .z.exit
exit 1   // error exit
```

---

## 5. Performance Traps

**Trap 1 — `select` vs functional form:**
```q
// String parse of select is slower (parses every time)
value "select from trade where date=2024.01.01"  // avoid in hot paths

// Functional form is faster (pre-parsed)
?[`trade; enlist(=;`date;2024.01.01); 0b; ()]
```

**Trap 2 — Attributes matter enormously:**
```q
// Without attribute: linear scan O(n)
select from trade where sym=`AAPL   // slow on large table

// With `g# attribute: hash lookup O(1) amortized
// With `p# attribute: binary search O(log n)
// Apply at load: update sym:`g#sym from `trade
```

**Trap 3 — Column extraction vs table query:**
```q
// Both return the column as a list on an unkeyed table
exec sym from trade
trade`sym
```

**Trap 4 — `count` before expensive operations:**
```q
// Always check count before costly operations
if[count r:select from trade where ...;
   // expensive work
  ]
```

**Trap 5 — String operations are slow on symbols:**
```q
// Slow: convert to string then compare
select from t where string[sym] like "AAPL*"

// Fast: symbol list membership
select from t where sym in `AAPL`AAPLV`AAPLW
```

**Trap 6 — Global modification in loops:**
```q
// Slow: extending global list in loop (reallocates each time)
r:();
do[1000; r,:enlist somevalue[]];

// Fast: build list then assign once
r:somevalue[] each til 1000
```

**Trap 7 — `.Q.gc[]` timing:**
```q
// GC pauses. In latency-sensitive processes, set g:0 (deferred GC)
// and call .gc.run[] (TorQ wrapper for .Q.gc[]) at safe points (post-EOD)
```

**Trap 8 — `peach` overhead:**
```q
// peach has serialization overhead — only worth it for large/slow operations
// For small fast operations, each is faster than peach
```

---

## 6. Date and Time Traps

**Trap 1 — Date arithmetic types:**
```q
q)2024.01.01 + 1         // 2024.01.02   (int+date=date)
q)2024.01.01 + 1.0       // 2024.01.02T00:00:00.000 (becomes a datetime, no error)
q)2024.01.02 - 2024.01.01  // 1          (date-date=int, not date)
```

**Trap 2 — Timestamp vs datetime:**
```q
// .z.p  = timestamp (nanosecond precision, UTC)
// .z.P  = timestamp (nanosecond precision, local time)
// .z.z  = datetime (float, millisecond precision, UTC) — DEPRECATED in favour of .z.p
// TorQ: use .proc.cp[] which returns .z.p or .z.P depending on -localtime flag
```

**Trap 3 — Date extraction:**
```q
q)`date$.z.p        // date part of timestamp
q)`time$.z.p        // time part (as time type)
q)`second$.z.p      // seconds since midnight (as second type)
q)"d"$2024.01.01    // same date (explicit cast)
```

**Trap 4 — EOD time calculation:**
```q
// .eodtime.nextroll gives next EOD roll time as timestamp
// TorQ timer set at: .eodtime.nextroll - 00:01 (one minute before)
// Adjusted for timezone offset between local and UTC
```

**Trap 5 — Time arithmetic:**
```q
q)12:00:00.000 + 1        // 12:00:00.001 (int counts milliseconds)
q)12:00:00.000 + 00:01    // 12:01:00.000 (time + minute = time)
q)12:00:00.000 + 0D00:01  // 0D12:01:00.000000000 (result is a timespan)
q)12:00:00.000 + 00:01:00.000000000  // 12:01:00.000 (time + timespan)
```

**Trap 6 — Timezone handling:**
```q
// .tz.t = timezone table (loaded from tz.csv)
// .tz.lg = local to GMT
// .tz.gl = GMT to local
// In TorQ: .eodtime.dailyadj adjusts for DST changes
```

**Trap 7 — Timestamp null vs date null:**
```q
q)null 0Np      // 1b (timestamp null)
q)null 0Nd      // 1b (date null)
q)0Np = 0Np    // 1b (same-type nulls compare equal; use null to test)
```

---

## 7. Namespace and Context Traps

**Trap 1 — `\d` persists for rest of file:**
```q
\d .myns
// ALL definitions here are in .myns
myfunc:{x+1}   // becomes .myns.myfunc

\d .
// Back to root
otherfunc:{x+1}  // root `otherfunc` (no namespace)
```

**Trap 2 — Backtick lookup in namespaces:**
```q
\d .myns
x:42
f:{value `x}   // looks up `x in current context = .myns.x = 42
g:{.myns.x}    // explicit — always works
```

**Trap 3 — `.` (root) vs `` `. `` (root namespace):**
```q
tables`.        // tables in root namespace
value `.        // all variables in root namespace
.Q.f[;2]       // .Q namespace function
```

**Trap 4 — Function local variables shadow globals:**
```q
a:10
f:{a:20; a}    // local a=20, global a unchanged
f[]            // 20
a              // 10 (unchanged)

// Use :: to modify global
g:{a::20}
g[]
a              // 20 (modified)
```

**Trap 5 — Max 8 parameters per function:**
```q
{[a;b;c;d;e;f;g;h] ...}  // OK (8 params max)
{[a;b;c;d;e;f;g;h;i] ...} // 'params error
// Workaround: pass dictionary as single arg
{[args] args[`a]+args[`b]} [`a`b!1 2]
```

---

## 8. Common q Idioms Reference

```q
// Safe value with default
@[value;`var;default]          // get var or default if undefined
@[f; arg; {defaultval}]        // call f with error trap

// Conditional assignment (only if not already set)
myvar:@[value;`myvar;42]

// Null-safe operations
42^0N                          // 42 (fill null with 42)
0^0N 1 0N                      // 0 1 0 (x^y fills nulls in y with x)

// In-place table update
update col:value from `mytable where condition

// Functional select
?[`t; where_clauses; by_clause; column_dict]

// Functional update
![`t; where_clauses; 0b; column_update_dict]

// Column extraction from unkeyed table (returns value vector)
t`col1                         // `a`b`c  — column as a list
// Note: does NOT work on keyed tables; use (0!t)`col1 to unkey first

// Safe dictionary merge (right wins)
d1,d2

// String formatting
"result: ",(string 42)  // "result: 42"
.Q.s1 value             // format any value as string (like 0N! but no print)
```
```

---