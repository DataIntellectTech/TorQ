---
name: torq-developer
description: TorQ framework and kdb+/q development. TRIGGER when: file is .q or in a TorQ repo; user asks about TorQ namespaces (.servers, .gw, .sub, .lg, .timer), process.csv, tickerplant/RDB/WDB/HDB/gateway, or EOD; user writes/reviews/debugs q code; kdb+ integration with Python (PyKX), Grafana, REST, or WebSockets. SKIP: unrelated q-named tooling (e.g. Qt, Q# language).
type: skill
---

TorQ is the Data Intellect production framework that wraps kdb+ with process management, connection tracking, logging, timers, pub/sub, and EOD lifecycle management. The authoritative source is the TorQ framework repo (commonly `$TORQHOME`); the Finance Starter Pack is the layered reference application.

Apply the rules below without exception. Every claim about TorQ internals cites a source file.

---

# CORE PRINCIPLES

These two principles are not duplicated by the specific rules below — everything else is covered in the lettered rules (N/C/L/H/T/S/P/M/G/Q/E/A).

1. **Fail fast** — if a required dependency is unavailable at startup, signal an error rather than starting in a degraded state. Use `.servers.startupdepcycles` or `.servers.startupdependent` to block until dependencies are ready. (`trackservers.q`)
2. **Read the downstream process before writing any IPC call** — before writing a function call or query string that will execute on another process, read that process's source files and config to establish what it actually exposes. Never assume a function exists based on a spec description or naming convention alone. This applies to every caller type: a q process calling another q process, a Python client calling a gateway, a gateway routing to a backend.

---

# CODE GENERATION RULES

## Namespace and Structure

- **Rule N1**: All process-specific code lives in a dedicated namespace (e.g., `\d .myproc`). Return to root at end of file with `\d .`. (`torq.q` pattern)
- **Rule N2**: Use `.proc.proctype` and `.proc.procname` to identify the current process — never hardcode process identity. (`torq.q`)
- **Rule N3**: The `parentproctype` flag loads shared code for a parent type before the child type. Use `-parentproctype wdb` for sort/sortworker processes that share wdb code. (FSP `process.csv`)
- **Rule N4**: `.api.add` every public function with signature and description. (`gateway.q:596-601`)

## Config Variables

- **Rule C1**: Every config variable must use the guard pattern: `myvar:@[value;\`myvar;default]`. This allows override from config files and command line. (`torq.q`)
- **Rule C2**: Config layering order (each layer overrides previous): `$KDBCONFIG/settings/default.q` → `$KDBSERVCONFIG/settings/default.q` → `$KDBAPPCONFIG/settings/default.q` → then each does `parentproctype.q` → `proctype.q` → `procname.q`. (`torq.q`)
- **Rule C3**: Any namespaced variable (`.ns.var`) can be overridden from the command line: `-ns.var value`. (`gettingstarted.md`)
- **Rule C4**: Never define config without a guard; if it is set before the config file loads it will be silently overwritten.
- **Rule C5**: The guard `@[value;\`myvar;default]` inside `\d .ns` resolves `.ns.myvar`, not root `.myvar`. To pre-set a config variable before loading (e.g. in tests or startup scripts), set the fully-qualified name: `.ns.myvar:value` — setting a root-level `myvar` will be ignored.

## Logging

- **Rule L1**: Standard output: `.lg.o[\`label;"message"]`. Error: `.lg.e[\`label;"message"]`. Warning: `.lg.w[\`label;"message"]`. (`torq.q`)
- **Rule L2**: `.lg.o` writes to stdout log (`out_` file). `.lg.e` writes to stderr log (`err_` file). Both write to in-memory `logmsg` table and publish via `.ps` if pubsub is active. (`torq.q`)
- **Rule L3**: Extend logging with `.lg.ext:{[loglevel;procname;label;msg] ...}` hook — this fires on every log call. (`torq-patterns.md`)
- **Rule L4**: Use `-jsonlogs` flag to switch log format to JSON (`.lg.format` is set by `torq.q` on startup).

## Message Handlers

- **Rule H1**: All `.z.*` overrides use `.dotz.set[\`.z.xx; newfunc]`. Never assign `.z.pc` etc. directly. (`torq.q`, `discovery.q`, `gateway.q`)
- **Rule H2**: To chain onto an existing handler: `{x@y; .myns.mypc[y]}@[value;.dotz.getcommand[\`.z.pc];{{[x]}}]`. (`gateway.q:523`)
- **Rule H3**: `.dotz.set` in FinSpace uses `.awscust.z` namespace — another reason to never bypass it. (`torq.q`)
- **Rule H4**: Message handlers loaded from `$KDBCODE/handlers/` directory. Disable all handlers with `.proc.loadhandlers:0b` in config. (`handlers.md`)

## Timers

- **Rule T1**: Repeating timer: `.timer.repeat[starttime;endtime;period;func;"description"]`. One-shot: `.timer.once[firetime;func;"description"]`. (`torq-patterns.md`)
- **Rule T2**: Timer modes — 0: reschedule at `T0+P` (fixed rate); 1: reschedule at `T1+P` (from fire time); 2: reschedule at `T2+P` (from completion). (`utilities.md`)
- **Rule T3**: A timer function that throws an error is removed from the timer (active set to 0b). Always wrap error-prone timer functions. (`.timer.timer` table, `cheatsheet.md`)
- **Rule T4**: Check timer is enabled: `if[not .timer.enabled; .lg.e[...]]` before registering timers. (`rdb.q:39`)

## Table Schemas

- **Rule S1**: Tables must have `time` as first column and `sym` as second column (for tickerplant subscription compatibility). (`SKILL.md`)
- **Rule S2**: `sym` column must carry `` `g# `` attribute in RDB in-memory tables for fast lookup: `sym:\`g#\`symbol$()`. (`database.q`, `tickerplant.q:40`)
- **Rule S3**: `upd` function must be at root namespace (not namespaced) so the tickerplant can call it. (`SKILL.md`, `tickerplant.q:34`)
- **Rule S4**: Any table that is published must have its schema defined on the receiving process. By default all schemas should be added to whatever schema file the tickerplant loads at startup (identified by the schemafile argument)
- **Rule S5**: Tables saved to HDB must be enumerated against the sym file using `.Q.en[hdbdir; table]` before writing. (`rdb.q:56`, `wdb.q`)
- **Rule S6**: After EOD writedown, re-apply attributes: functional update `![table;();0b;dict_of_attr_exprs]` each table. (`rdb.q:115`)
- **Rule S7**: All tables in the tickerplant schema file must be **unkeyed** (type 98h). The tickerplant's `.u.upd` and `.u.init` functions only handle plain tables — a keyed table (type 99h) causes startup failure. If a process needs upsert semantics for its internal state (e.g. a last-value cache), define the keyed table privately in its own namespace and publish an unkeyed flattened version (`0!`) to the tickerplant.

## Subscriptions and Tickerplant

- **Rule P1**: Subscribe using `.sub.subscribe[tables;syms;schema;replaylog;proc]` — do not write your own subscription protocol. The 5th arg `proc` is a dictionary row from `.sub.getsubscriptionhandles[proctype;procname;attributes]`, not a raw integer handle. Always resolve the proc dict at startup before calling subscribe. (`subscriptions.q:80`, `rdb.q:163-169`)
- **Rule P2**: Tables to ignore at EOD (not saved to disk): define in `ignorelist` variable, default `` `heartbeat`logmsg ``. (`rdb.q:18`)
- **Rule P3**: The `subfiltered` flag in rdb enables column/row filtering at subscription time. (`rdb.q:33`)

## Connection Management

- **Rule M1**: Declare which process types to connect to: `.servers.CONNECTIONS:\`rdb\`hdb\`gateway` (source: `trackservers.q:13`). Then call `.servers.startup[]` explicitly at the end of the load file — TorQ does NOT call this automatically; every process is responsible for calling it itself. The RDB/WDB call it inside their own startup functions. (`rdb.q:211`, `gateway.q:532`, `filealerter.q:191`)
- **Rule M2**: Get handles: `.servers.getservers[\`proctype;\`hdb;()!();1b;0b]` returns a table with `w` (handle), `procname`, `proctype`, `hpup`, `attributes`, `attribmatch`. (`trackservers.q:75-89`)
- **Rule M3**: Shortcut: `.servers.gethandlebytype[\`hdb;\`roundrobin]` returns a single handle using `roundrobin`, `any`, or `last` selection. (`trackservers.q:106`)
- **Rule M4**: `.servers.SERVERS` table columns: `procname`, `proctype`, `hpup`, `w` (handle int), `hits` (int), `startp` (timestamp), `lastp` (timestamp), `endp` (timestamp), `attributes` (dict). (`trackservers.q:10`)
- **Rule M5**: IPC type per proctype: `.servers.SOCKETTYPE:enlist[\`tickerplant]!enlist \`unix`. Options: `` `tcp`tcps`unix ``. (`conn.md`, `trackservers.q:29`)
- **Rule M6**: Password file location: `$KDBCONFIG/passwords/`. Hierarchical: `default.txt` → `proctype.txt` → `procname.txt`. (`trackservers.q:44`)
- **Rule M7**: Non-TorQ processes go in `$KDBCONFIG/settings/nontorqprocess.csv`. Enable with `.servers.TRACKNONTORQPROCESS:1b`. (`conn.md`)

## Gateway Patterns

- **Rule G1**: Async (deferred-sync) call: `neg[h](`.gw.asyncexec`;query;\`rdb); h[]`. The `h[]` blocks until result returns. (`gateway.q:597`)
- **Rule G2**: Async with join function and postback: `.gw.asyncexecjpt[query;servertype;joinfunction;postback;timeout]`. (`gateway.q:596`)
- **Rule G3**: Sync call: `h(`.gw.syncexec`;query;\`rdb\`hdb)`. Uses `-30!` deferred sync on kdb+≥3.6. (`gateway.q:479`)
- **Rule G4**: `servertype` argument can be: symbol list `` `rdb`hdb `` (OR — any matching type), or a dict of attributes `` enlist[`tables]!enlist enlist`trade `` (filter by attribute). (`gateway.q:392-408`)
- **Rule G5**: Gateway blocks queries during EOD reload (`.gw.eod` flag). `reloadstart` propagates timeout errors to in-flight queries; `reloadend` re-enables after HDB reload. (`gateway.q:560-577`)
- **Rule G6**: Register process attributes for routing: `update attributes:(enlist mydict) from \`.gw.servers where servertype=\`hdb`. Use `.proc.getattributes` to expose process attributes. (`gateway.q:579-587`)
- **Rule G7**: `.servers.addprocscustom` on the gateway calls `runnextquery[]` and `addserversfromconnectiontable` when new processes register. (`gateway.q:543-548`)

## q Language Pitfalls

- **Rule Q1**: `-x` where x is a variable name containing a numeric type will fail with a 'type error. Only use `-` when directly referencing the numeric literal e.g. `-1`, `-0.5`, `-1j`. For variables, use `neg x`.
- **Rule Q2**: Symbols containing hyphens (e.g. `` `GBP-USD ``) cannot be written with backtick syntax in q. Always cast from a string: `` `$"BTC-USD" ``.
- **Rule Q3**: `enlist x` where `x` is a symbol atom produces type 11h (symbol list) as required by typecheck functions. `enlist enlist x` produces type 0h (generic list) and will fail type checks. If you're unsure if x will always be a list, use `x:x,()` at the start of the function to ensure it's always a list (empty or not).

## EOD Patterns

- **Rule E1**: Add custom EOD logic by overriding `.save.postreplay:{[hdbdir;date] ...}`. This is called after all tables are written, before HDB reload. (`rdb.q:43`, `wdb.q:79`)
- **Rule E2**: Manipulate tables before EOD writedown via `.save.savedownmanipulation:enlist[\`trade]!enlist myFunc`. (`rdb.q:42`)
- **Rule E3**: `endofday` function is placed at root namespace (`endofday:.rdb.endofday`) so tickerplant can call it by name. (`rdb.q:214`)
- **Rule E4**: WDB modes: `saveandsort` (default), `save` (save only, signal sort process), `sort` (sort only). Set via `.wdb.mode`. (`wdb.q:12`)
- **Rule E5**: WDB notifies gateway via `informgateway(\`reloadstart;\`)` before sorting, `informgateway(\`reloadend;\`)` after. (`wdb.q:261`, `wdb.q:278`)
- **Rule E6**: HDB reload triggered by WDB calling `notifyhdb` which sends `` (`reload;date) `` to each HDB handle. (`rdb.q:82-83`)
- **Rule E7**: RDB with `reloadenabled:1b` does not save to disk — instead stores row counts, then WDB calls `reload` on the RDB to drop old rows. (`rdb.q:95-101`)

## API Documentation

- **Rule A1**: Document all public functions: `.api.add[\`.ns.func;1b;"description";"params";"return"]`. (`gateway.q:596`)
- **Rule A2**: Search functions: `.api.f\`pattern` (all), `.api.p\`pattern` (public), `.api.u\`pattern` (user-defined). (`.api.s"*pattern*"` searches function bodies.) (`utilities.md`)
- **Rule A3**: Export current config: `.api.exportconfig[\`.myns]` returns table of all variables with current values. (`utilities.md`)

---

# CODE REVIEW CHECKLIST

1. **Namespace discipline** — Does all code use `\d .ns` / `\d .` correctly? No accidental root-namespace pollution?
2. **Config guard pattern** — Every config variable uses `@[value;\`var;default]`?
3. **No raw `hopen`** — All connections go through `.servers.*` functions?
4. **`CONNECTIONS` completeness** — Every proctype passed to `.servers.gethandlebytype` or `.servers.getservers` is explicitly listed in `.servers.CONNECTIONS`? A missing entry silently produces `0Ni` handles at runtime with no error at definition time.
5. **`.dotz.set` for handlers** — No direct `.z.*` assignment?
6. **Logging** — `.lg.o`/`.lg.e`/`.lg.w` used (not `0N!`)?
7. **Timer safety** — Timer-called functions wrapped in error traps so failures don't silently remove them from the timer?
8. **Table schema** — `time` first, `sym` second, `` `g# `` on sym, `upd` at root namespace? Every table published via `upd` has a matching entry in the tickerplant's `-schemafile`?
9. **`endofday` at root** — `endofday` and `reload` assigned to root namespace so TP can call them?
10. **EOD hooks** — Custom EOD logic uses `.save.postreplay`/`.save.savedownmanipulation` rather than modifying core functions?
11. **`.api.add`** — All public functions documented?
12. **Error trapping** — `@[f;arg;{.lg.e[\`label;x]}]` or `.[f;args;{.lg.e[\`label;x]}]` used around operations that can fail?
13. **Subscription** — Uses `.sub.subscribe`, respects `ignorelist`, handles `reloadenabled` flag?
14. **Gateway routing** — `servertype` can be dict for attribute-based routing; EOD guard in place?
15. **IPC type** — Connection type (tcp/tcps/unix) configured via `.servers.SOCKETTYPE` not hardcoded?
16. **Dependency startup** — Process blocks until required connections are available using `.servers.startupdepcycles`?
17. **Credentials** — New process has a `$KDBAPPCONFIG/passwords/{proctype}.txt` (or `procname.txt`) file, AND its username appears in the `U` access list file of every process it connects to? Missing either side silently gives `'access` at connection time.
18. **IPC call verification** — For every new IPC call or query string targeting a downstream process: have you read that process's source files and config to confirm the function exists there? For a gateway: have you checked its settings file and any loaded shared code (e.g. `appconfig/settings/gateway.q`, `code/cryptofunctions/`) to distinguish functions that live on the gateway itself from those that must be routed to a backend via `.gw.syncexec`/`.gw.asyncexec`? (Core Principle 2)
19. **Staged new-process workflow** — When the change introduces a NEW process: is Stage 1 (plumbing — schemas, skeleton, `CONNECTIONS`, credentials, `process.csv` entry, subscription registration) cleanly separable from Stage 2 (feature logic)? If a single change mixes plumbing and feature logic, flag it and request Stage 1 be verified to start and connect on its own first. See PROCESS SETUP GUIDE.

---

# PROCESS SETUP GUIDE

**New processes must be added in two stages with a hard verification gate between them.** Do not write any feature/business logic in Stage 1, and do not begin Stage 2 until Stage 1 verification passes. Layering feature code onto broken plumbing produces bugs that look like logic errors but aren't — they waste hours and lead to wrong fixes.

If you are asked to "add a process that does X", translate this into: Stage 1 first, verify, then Stage 2 for X. Do not collapse the stages to save time.

## Stage 1 — Plumbing

Goal: a process that starts cleanly, opens handles to every declared downstream connection, and (if it subscribes) registers with the tickerplant. **No business logic.**

Tasks:

1. **Schemas** — define any new published tables in the tickerplant's `-schemafile` (Rule S4). Unkeyed (Rule S7); `time` first, `sym` second with `` `g# `` (Rules S1, S2).
2. **Skeleton** (`code/processes/myproc.q`):
   - Open namespace: `\d .myproc`
   - Config guards on every tunable (Rule C1)
   - Entry function that only logs (e.g. `run:{[] .lg.o[\`run;"stub"]}`) — no real work
   - Return to root: `\d .`
   - Root-level `upd` if the process subscribes (Rule S3)
3. **Connections** — `.servers.CONNECTIONS:\`typeA\`typeB\`…` listing every downstream proctype (Rule M1). Call `.servers.startup[]` at end of file.
4. **Credentials** — create `$KDBAPPCONFIG/passwords/{proctype}.txt` AND append the user to the `U` access list of every process this one will connect to (checklist item 17).
5. **Register** — add a row to `$KDBAPPCONFIG/process.csv` (column format in `torq-process-templates.md`).
6. **Subscribe (if applicable)** — block until the TP is up with `.servers.startupdepcycles`, then call `.sub.subscribe` with the proc dict from `.sub.getsubscriptionhandles` (Rule P1).

For the skeleton template and proctype-specific templates, read `torq-process-templates.md`.

## Stage 1 Verification — blocks Stage 2

Start the process and confirm **every** item below before writing a single line of feature logic:

- [ ] Process starts: `./torq.sh start {procname}` succeeds and the PID persists (no immediate exit)
- [ ] `err_{procname}_*.log` contains no `ERR` lines after startup
- [ ] `out_{procname}_*.log` shows the expected startup/connection messages
- [ ] In qcon: `select proctype, w from .servers.SERVERS where proctype in .servers.CONNECTIONS` — every row has a non-null `w`
- [ ] If subscribing: `.sub.SUBSCRIPTIONS` shows the expected tables/syms, and on the TP `exec w from .u.w.{table}` includes this process's handle
- [ ] If publishing: the receiving process has the table schema loaded (`tables \`.` includes the new table)

If any check fails: stop, diagnose, and fix. Do not proceed to Stage 2 to "see if it still works" — it will mask whichever Stage 1 issue is still broken.

## Stage 2 — Feature logic

Only after Stage 1 verification passes. Add query/timer/publish/subscription-processing logic one piece at a time, each with `.lg.o` breadcrumbs, and confirm each against the running process before adding the next.

---

# DEPLOYMENT

For env vars, deployment directory layout, `setenv.sh`, `process.csv` columns, config/code layering order, and `torq.sh` commands, read `torq-process-templates.md`.

---

# DEBUGGING GUIDANCE

## First Steps

1. Check **error log** (`err_` file in `$KDBLOGS`) — should be empty in healthy system
2. Query **`.usage.usage`** — sorted by `timer` descending to find slow timer calls
3. Check **`.timer.timer`** — `active=0b` means the function threw an error and was removed
4. Check **`.servers.SERVERS`** — `endp` not null means a connection died
5. Check **`.clients.clients`** — frequent connect/disconnect cycles indicate client issues

## TorQ Diagnostic Functions

```q
.usage.usage                        // all queries (status "b"=before, "c"=complete, "e"=error)
select from .usage.usage where time within (start;end)
100 sublist `timer xdesc .usage.usage  // slowest timer calls

.timer.timer                        // scheduled timer calls; active=0b means disabled by error
.servers.SERVERS                    // outbound connections
.clients.clients                    // inbound connections

.api.f`pattern                      // find functions/vars matching pattern
.api.p`pattern                      // public functions only
.api.s"*pattern*"                   // search function bodies
.api.m[]                            // memory usage of all variables
.api.exportconfig[`.myns]           // current config values for namespace
.api.whereami[.z.s]                 // name of current function (useful in errors)

.Q.w[]                              // workspace: used/heap/peak/wmax/mphy
.gc.run[]                           // force garbage collection
```

## Common Error Table

| Error | Likely Cause |
|---|---|
| `'type` | Wrong type passed to function; check `-7h$x` type codes |
| `'length` | Conformability issue in vector operation |
| `'domain` | `til -1`, enum lookup failure, out-of-range cast |
| `'value` | Undefined variable or function; check namespace |
| `'wsfull` | Out of memory; call `.gc.run[]`, check `.Q.w[]` |
| `'conn` | Too many connections (pre-4.1t limit: 1022); or connection refused |
| `'timeout` | `hopen` timeout (`.servers.HOPENTIMEOUT`); or query timeout (`-T`) |
| `'access` | Auth failure or `.access` restrictions; check `.z.pw` / access list |
| `'stack` | Recursion too deep; replace with iterators |
| `'globals` | Too many global variables in function (max 8 params) |
| `'assign` | Attempt to modify a constant or read-only table |

## Debugging Workflow

```bash
# 1. Stop process
./torq.sh stop rdb1

# 2. Debug in foreground (shows full startup)
./torq.sh debug rdb1

# Or with error trapping to see past startup errors:
q torq.q -proctype rdb -procname rdb1 -trap -debug -load code/processes/rdb.q

# 3. In the q session, inspect state:
q).servers.SERVERS       // are connections up?
q)tables`.             // what tables exist?
q).usage.usage         // recent queries
```

## Missing Data — Debugging Protocol

When a table is not populating and there are no obvious errors, work from the data inward — not from the framework outward. Do not start by reading subscription/distribution source.

1. **Check live state** — qcon into the receiving process. Does the table exist? Does it have rows? Then qcon into the upstream publisher and confirm data exists there.

2. **Call `upd` directly** — every subscriber has a root-level `upd` (or equivalent function). Call it manually with a representative row and check whether the downstream state updates as expected.

4. **Trace logic line by line** — copy the body of the suspect function into the q session and run each statement in isolation using real values from the live state. Check intermediate results: empty tables after a filter, null handles, and wrong timestamps all become obvious immediately without needing to reason about the surrounding framework.

5. **Check the plumbing last** — only if data exists upstream, `upd` works with test input, and the logic is sound should you look at the subscription layer: `.u.w` on the TP, `.servers.SERVERS` on the subscriber, recent errors in `.usage.usage`.

## localtime vs Data Timestamps

`localtime` in `process.csv` controls whether `.proc.cp[]` returns `.z.P` (local) or `.z.p` (UTC). This setting is independent of the timestamps carried in the data itself, which are determined by the feed source.

If processes run with `localtime:1` but the feed produces UTC timestamps, any time comparison between `.proc.cp[]` and a data `time` column will be off by the local UTC offset. Staleness filters, time-windowed selects, and EOD logic are all affected. Set `localtime:0` for all processes when the feed produces UTC data.

## Combining Out and Error Logs

```bash
# Merge and sort both log files chronologically
sort -nk1 out_rdb1_*.log err_rdb1_*.log

# Find last N lines before an error
sort -nk1 out_rdb1_*.log err_rdb1_*.log | grep -B 20 ERR
```

## Key Flags for Debugging

- `-debug`: equivalent to `-nopi -noredirect` (interactive q session, no log redirect)
- `-trap`: catch init errors and continue
- `-stop`: halt at init error without exiting
- `-noconfig`: skip config loading (test with bare TorQ)
- `-onelog`: write all output to stdout log (easier to grep)

---

# COMPANION FILES

Only read when the current task matches — these are not auto-loaded.

- **`torq-internals.md`** — read when debugging startup order, EOD sequence, gateway request lifecycle, or discovery protocol.
- **`torq-patterns.md`** — read when authoring new process code: namespace table, IPC/subscription patterns, caching, async helpers, error-trapping idioms.
- **`torq-process-templates.md`** — read when creating a new process, editing `process.csv`, setting up deployment, or needing a concrete template (minimal proc, feedhandler, RDB, WDB, gateway). Also holds env vars, `setenv.sh`, `torq.sh` commands, and the deployment checklist.
- **`q-language-reference.md`** — general q/kdb+ reference (not TorQ-specific). Read when hitting type errors, iterator edge cases, IPC quirks, date/time traps, or performance issues.
- **`kdb-ecosystem.md`** — read when integrating kdb+ with Python (PyKX/embedPy), Grafana, REST/HTTP, WebSockets, or C API.
```

---