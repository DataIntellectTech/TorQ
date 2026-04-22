# TorQ Patterns Reference

## Namespace Table

| Namespace | Script | Purpose |
|---|---|---|
| `.proc` | `torq.q` | Process identity, startup hooks, loading utilities |
| `.lg` | `torq.q` | Logging: `.lg.o`/`.lg.e`/`.lg.w`, JSON log support, hook `.lg.ext` |
| `.timer` | `timer.q` | Multiple function timer: `.timer.repeat`/`.timer.once`/`.timer.timer` |
| `.hb` | `heartbeat.q` | Heartbeat publication and monitoring |
| `.sub` | `pubsub.q` | Subscription: `.sub.subscribe`, `.sub.SUBSCRIPTIONS`, `.sub.getsubscriptionhandles` |
| `.ps` | `pubsub.q` | Publish/subscribe: `.ps.publish`, `.ps.subscribe`, `.ps.initialise` |
| `.api` | `api.q` | Function documentation, search, memory usage |
| `.dotz` | `dotz.q` | Handler management: `.dotz.set`, `.dotz.getcommand` |
| `.servers` | `trackservers.q` | Connection registry: `.servers.SERVERS`, `.servers.getservers`, `.servers.startup` |
| `.clients` | `trackclients.q` | Inbound connection tracking: `.clients.clients` |
| `.access` | `controlaccess.q` | Access control: user whitelist, IP restriction, function restriction |
| `.usage` | `logusage.q` | Query logging: `.usage.usage`, LEVEL config |
| `.os` | `os.q` | OS utilities: `.os.sleep`, `.os.pth`, `.os.ren`, `.os.deldir` |
| `.gc` | `gc.q` | Garbage collection wrapper: `.gc.run[]` |
| `.loader` | `loader.q` | CSV/flat file loading utilities |
| `.cache` | `cache.q` | Function result caching: `.cache.add`, `.cache.maxsize` |
| `.async` | `async.q` | Async helpers: `.async.deferred`, `.async.postback` |
| `.cmp` | `compression.q` | Compression utilities |
| `.email` | `email.q` | Email sending via C lib |
| `.tz` | `timezone.q` | Timezone conversions: `.tz.lg`, `.tz.gl` |
| `.eodtime` | `eodtime.q` | EOD roll time: `.eodtime.nextroll`, `.eodtime.dailyadj` |
| `.ds` | `datasource.q` | Data source abstraction |
| `.rdb` | `rdb.q` | RDB-specific: `endofday`, `reload`, `subscribe`, `writedown` |
| `.wdb` | `wdb.q` | WDB-specific: `endofday`, `savetodisk`, modes, merge |
| `.gw` | `gateway.q` | Gateway: `asyncexec`, `syncexec`, `asyncexecjpt`, `servers`, `queryqueue` |
| `.pm` | `permissioning.q` | Permission management: `.pm.allowed` |
| `.ldap` | `ldap.q` | LDAP authentication |
| `.readonly` | `writeaccess.q` | Read-only mode |
| `.zpsignore` | `zpsignore.q` | Async message pattern filtering |
| `.mon` | `monitor.q` | Process monitoring |
| `.save` | `dbwriteutils.q` | EOD hooks: `.save.postreplay`, `.save.savedownmanipulation`, `.save.manipulate` |
| `.sort` | `sort.q` | Sort configuration from sort.csv: `.sort.sorttab`, `.sort.getsortcsv` |
| `.merge` | `merge.q` | WDB merge operations for partbyattr modes |
| `.finspace` | (FinSpace code) | AWS FinSpace integration flag: `.finspace.enabled` |

---

## Config Layering

```
KDBCONFIG/settings/default.q         ← lowest priority (TorQ defaults)
KDBCONFIG/settings/{parentproctype}.q
KDBCONFIG/settings/{proctype}.q
KDBCONFIG/settings/{procname}.q
KDBSERVCONFIG/settings/default.q
KDBSERVCONFIG/settings/{parentproctype}.q
KDBSERVCONFIG/settings/{proctype}.q
KDBSERVCONFIG/settings/{procname}.q
KDBAPPCONFIG/settings/default.q      ← app-level (FSP etc)
KDBAPPCONFIG/settings/{parentproctype}.q
KDBAPPCONFIG/settings/{proctype}.q
KDBAPPCONFIG/settings/{procname}.q   ← highest priority
command line: -.ns.var value         ← overrides everything
```

---

## Logging Patterns

```q
// Standard logging
.lg.o[`label;"info message"]        // INF → out_ log file
.lg.e[`label;"error message"]       // ERR → err_ log file (should be empty in production)
.lg.w[`label;"warning message"]     // WRN → out_ log file

// Extend all logging (fires on every .lg.* call)
.lg.ext:{[loglevel;procname;label;msg]
  // e.g. push to monitoring system, alert on ERR
  if[loglevel=`ERR; .email.send[...]]
  }

// JSON logs: start with -jsonlogs flag
// torq.q sets .lg.format to JSON formatter
```

---

## Handler Management

```q
// Set a new handler (correct way)
.dotz.set[`.z.pc; mynewhandler]

// Chain onto existing handler
.dotz.set[`.z.pc;
  {.myns.mypc[y]; x@y}                          // call mine then existing
  @[value; .dotz.getcommand[`.z.pc]; {;}]        // get current (or no-op)
  ]

// Get current handler command (the function assigned, before TorQ wrapping)
.dotz.getcommand[`.z.pc]
```

Available handlers (from `handlers.md`):
- `logusage.q` — modifies pw, po, pg, ps, pc, ws, ph, pp, pi, exit, timer
- `controlaccess.q` — modifies pw, pg, ps, ws, ph, pp, pi
- `trackclients.q` — modifies po, pg, ps, ws, pc
- `trackservers.q` — modifies pc, timer
- `zpsignore.q` — modifies ps
- `writeaccess.q` — modifies pg, ps, ws, ph, pp
- `ldap.q` — modifies pw

---

## Timer Scheduling Modes

```q
// Repeating timer
// mode 0: reschedule at T0+P (fixed rate — can backlog if slow)
// mode 1: reschedule at T1+P (from when it fired — can drift)
// mode 2: reschedule at T2+P (from when it finished — safest for slow functions)
.timer.repeat[starttime; endtime; period; func; "description"; mode]
// mode defaults to 0 if omitted

// One-shot timer
.timer.once[firetime; func; "description"]

// Inspect timer
.timer.timer    // table of scheduled functions (active=0b means disabled by error)

// Timer is driven by .z.ts; must start kdb+ with -t <ms> or use system"t <ms>"
```

---

## Subscription Management

```q
// Subscribe to tickerplant
// Returns dict: `subtables`tplogdate
subinfo:.sub.subscribe[
  `trade`quote;      // tables (` = all)
  `;                 // syms (` = all)
  1b;                // retrieve schema?
  1b;                // replay log?
  handle             // TP handle
  ]

// Get subscription handles (for a process type)
handles:.sub.getsubscriptionhandles[`tickerplant;();()!()]

// Subscription state
.sub.SUBSCRIPTIONS   // table of active subscriptions

// Custom upd handler (must be at ROOT namespace)
upd:{[t;x] t insert x}   // simplest form
```

---

## IPC Patterns

### Synchronous
```q
h:first exec w from .servers.getservers[`proctype;`hdb;()!();1b;1b]
result:h (`.proc.procname;`)
result:h ({select from trade where date=.z.d};`)
```

### Asynchronous (Fire and Forget)
```q
neg[h] (`.myns.myfunc; arg1; arg2)
neg[h] (::)   // flush to ensure message is sent
```

### Deferred Synchronous (client blocks)
```q
// Client sends async, blocks on handle until server responds via neg[.z.w]
neg[h] (`.gw.asyncexec; query; `rdb)
result:h[]   // block
```

### Postback (client continues)
```q
// Server will call .myns.callback[result] on client
neg[h] (`.gw.asyncexecjpt; query; `rdb; raze; `.myns.callback; 0Wn)
```

### Broadcast to Multiple
```q
// Send same message to multiple handles
(neg each handles) @\: (`.myns.func; arg)
// Then flush each
(neg each handles) @\: (::)
```

### .async Helpers
```q
// Deferred sync to multiple handles (blocks until all respond)
.async.deferred[handles; (query; arg)]   // returns (success_list; result_list)

// Postback to multiple handles
.async.postback[handles; query; `callbackfunc]  // returns success vector immediately
```

---

## Connection Management Patterns

```q
// Declare connections at startup
.servers.CONNECTIONS:`rdb`hdb`gateway

// Then call startup (usually done automatically by TorQ)
.servers.startup[]

// Get all available HDB handles
hdbs:exec w from .servers.getservers[`proctype;`hdb;()!();1b;0b]

// Get single handle with selection strategy
h:.servers.gethandlebytype[`hdb;`roundrobin]   // rotate through HDBs
h:.servers.gethandlebytype[`hdb;`any]          // random
h:.servers.gethandlebytype[`hdb;`last]         // most recently used

// Get handle to specific process name
h:first exec w from .servers.getservers[`procname;`rdb1;()!();1b;1b]

// Attribute-based lookup
// Find HDB with specific date range
req:`date`tables!(enlist 2024.01.01; enlist enlist`trade)
tab:.servers.getservers[`proctype;`hdb;req;1b;0b]
// attribmatch column shows which attributes matched

// Block until required processes are available
.servers.startupdepcycles[`tickerplant; 10; 100]  // wait up to 100*10s=1000s
.servers.startupdependent[`hdb]                   // wait forever
```

---

## EOD Extension Patterns

```q
// Post-writedown hook (runs after save, before HDB reload)
.save.postreplay:{[hdbdir;date]
  .lg.o[`postreplay;"custom EOD work"];
  // copy files, send emails, trigger external systems
  }

// Table manipulation before save
.save.savedownmanipulation:enlist[`trade]!enlist {[data]
  select from data where size > 0
  }

// Custom HDB notification message
.rdb.hdbmessage:{[date] (`customreload; date)}

// Register custom function at EOD completion
.proc.addinitlist {[] .lg.o[`init;"EOD handlers registered"]}
```

---

## Caching

```q
// Cache result of expensive function
cachedresult:.cache.add[{expensivequery[]}; `mycachekey; `status]

// Config
.cache.maxsize:500000000      // max total cache size in bytes
.cache.maxindividual:50000000 // max size of single cache entry
```

---

## Error Trapping Patterns

```q
// Safe value retrieval
result:@[value;`myfunc;{.lg.e[`label;x];::}]

// Safe IPC call
result:@[handle;(query;arg);{.lg.e[`ipc;x]; 0#()}]

// Safe multi-arg call
result:.[func;(arg1;arg2);{.lg.e[`label;x]}]

// Re-raise after logging
result:@[func;arg;{.lg.e[`label;x];'x}]  // re-signal the error

// Return null table on error
result:@[{select from trade where date=x};date;{0#trade}]
```

---

## Process Attribute Pattern

Expose process capabilities for intelligent gateway routing:

```q
// In your proctype settings or init code:
.proc.getattributes:{[]
  `tables`date!(tables`.;.rdb.rdbpartition)
  }

// Gateway then routes by attribute:
// servertype=enlist[`tables]!enlist enlist`trade  → only processes with trade table
// servertype=enlist[`date]!enlist enlist 2024.01.01  → only processes with that date
```

---

## .api Functions Quick Reference

```q
.api.f `pattern        // find all matching functions/vars (case insensitive)
.api.p `pattern        // public only
.api.u `pattern        // user-defined only
.api.s "*pattern*"     // search function bodies
.api.m[]               // memory usage table (sorted by size)
.api.mem[0b]           // memory without evaluating views
.api.whereami[.z.s]    // name of current function
.api.exportconfig[`.myns]  // table of all config vars in namespace
.api.exportallconfig[]     // all TorQ namespaces
.api.torqnamespaces        // list of TorQ namespaces

// Document a function
.api.add[`.ns.func; 1b; "description"; "params"; "return"]
```
```

---