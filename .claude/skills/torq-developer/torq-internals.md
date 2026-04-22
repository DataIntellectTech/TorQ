# TorQ Internals Deep Reference

## 1. torq.q Startup Sequence

Source: `torq.q` (in the TorQ framework repo)

### Stage 1: Environment and `.proc` Namespace

torq.q begins by entering `\d .proc` and defining:
- `.proc.loaded:0b` — set to `1b` after full initialisation
- `.proc.initialised:0b` — set to `1b` after `.proc.initlist` runs
- `.proc.initlist:()` — list of `{[]}` functions to run at end of startup
- `.proc.addinitlist:{[f] .proc.initlist,:enlist f}` — register init callbacks

**Startup flags read from `.z.x` via `.Q.opt`:**

| Flag | Effect |
|---|---|
| `-proctype` | Sets `.proc.proctype` |
| `-procname` | Sets `.proc.procname` |
| `-parentproctype` | Sets `.proc.parentproctype` |
| `-procfile` | Override process.csv path |
| `-localtime` | Switch `cp`/`cd`/`ct` from UTC to local time |
| `-trap` | Catch init errors, continue |
| `-stop` | Halt at init error, don't exit |
| `-debug` | `-nopi -noredirect` |
| `-noredirect` | Don't redirect stdout/stderr to log files |
| `-noconfig` | Skip config loading |
| `-nopi` | Reset `.z.pi` to default |
| `-jsonlogs` | Switch log format to JSON |
| `-test` | Unit test mode |
| `-onelog` | All output to stdout log |

### Stage 2: Logging Setup (`.lg` Namespace)

```
.lg.outmap  — dict of log level → output handle (default: 1 for stdout)
.lg.pubmap  — dict of log level → whether to publish via .ps
.lg.format  — log line formatter (plain or JSON depending on -jsonlogs)
.lg.publish — publishes to logmsg table via .ps.publish if pubsub active
.lg.l       — low-level log function
.lg.o       — info (INF) log
.lg.e       — error (ERR) log  
.lg.w       — warning (WRN) log
.lg.ext     — empty hook; override to extend all logging
```

### Stage 3: Environment Variable Substitution

`.rmvr.removeenvvar` substitutes `{ENV_VAR}` patterns in strings read from process.csv. This is how `{KDBBASEPORT}+1` works in port columns.

### Stage 4: Process Identification

Reads `process.csv` via `readprocfile`. Identifies itself by matching `host` + `port` in the CSV, OR uses explicit `-proctype`/`-procname` flags. If neither works, process exits with error.

### Stage 5: Log File Redirection

stdout and stderr redirected to timestamped files in `$KDBLOGS`:
- `out_{proctype}_{procname}_{timestamp}.log`
- `err_{proctype}_{procname}_{timestamp}.log`
- `usage_{proctype}_{procname}_{timestamp}.log`

Aliases created without timestamp suffix (unless `-noredirectalias`).

### Stage 6: Config Loading

For each config root (`KDBCONFIG`, `KDBSERVCONFIG`, `KDBAPPCONFIG`), in order:
1. `settings/default.q`
2. `settings/{parentproctype}.q` (if parentproctype set)
3. `settings/{proctype}.q`
4. `settings/{procname}.q`

Files that don't exist are silently skipped.

### Stage 7: Code Loading

`reloadallcode` function iterates code roots (`KDBCODE`, `KDBSERVCODE`, `KDBAPPCODE`) and for each loads:
1. `common/` — shared utilities
2. `{parentproctype}/` — parent type code
3. `{proctype}/` — process type specific code
4. `{procname}/` — process name specific code
5. `handlers/` — message handler customisations

Then loads any `-load` / `-loaddir` files specified on command line.

### Stage 8: Pubsub and Servers Initialisation

1. `.ps.initialise[]` — initialise publish/subscribe system
2. `.servers.startup[]` — read process.csv, connect to discovery, make initial connections

### Stage 9: Init Callbacks and Finalisation

1. Runs each function in `.proc.initlist`
2. Sets `.proc.initialised:1b`
3. Sets `.proc.loaded:1b`
4. If `-test` flag: runs unit tests and exits

---

## 2. Gateway Internals

Source: `code/processes/gateway.q`

### Key Tables

```q
// Keyed on queryid: tracks pending queries
queryqueue:([queryid:`int$()] clienth:`int$(); query:(); servertype:();
             queryattributes:(); joinfunction:(); postback:();
             timeout:`timespan$(); sync:`boolean$(); 
             senttime:`timestamp$(); returntime:`timestamp$())

// Tracks query results from backend servers
results:([]queryid:`int$(); serverid:`int$(); result:())

// Backend server registry (keyed on serverid)
servers:([serverid:`int$()] handle:`int$(); servertype:`symbol$();
          active:`boolean$(); inuse:`boolean$(); usage:`timespan$();
          attributes:())

// Connected clients
clients:([]handle:`int$(); connecttime:`timestamp$())
```

### Request Lifecycle (Async Path)

1. **Client calls** `neg[gw_handle](`.gw.asyncexecjpts`;query;servertype;joinf;postback;timeout;sync)`
2. **`asyncexecjpts`** validates: correct function type (sync vs async), permissions, servertype resolution
3. **`addquerytimeout`** inserts row into `queryqueue`
4. **`runnextquery`** → `runquery` checks if any queries in queue can be served
5. **`availableserverstable`** finds servers not `inuse` that match required servertype/attributes
6. **`sendquerytoserver`** sends async: `(neg handles)@\:(serverexecute;queryid;query)` 
7. **Backend executes** `serverexecute[queryid;query]` → sends result back: `neg[.z.w](`.gw.addserverresult`;queryid;result)`
8. **`addserverresult`** / **`addservererror`** stores result row
9. **`checkresults`** fires when all parts of a query are complete: applies join function
10. **`sendclientreply`** sends result: `-30![handle]` for sync (deferred-sync), `neg[handle]` for async with postback

### Public API Functions

```q
// [query; servertype; joinfunction; postback; timeout; sync]
// Most general form. sync=1b means treat as sync (deferred-sync pattern)
asyncexecjpts:{[query;servertype;joinfunction;postback;timeout;sync] ...}

// [query; servertype; joinfunction; postback; timeout]
// Async version (sync=0b projection of asyncexecjpts)
asyncexecjpt:asyncexecjpts[;;;;;0b]

// [query; servertype]  
// Deferred-sync: client sends async, blocks on handle. join=raze, no postback, no timeout
asyncexec:asyncexecjpt[;;raze;();0Wn]

// [query; servertype; joinfunction; timeout]
// Uses -30! deferred sync on kdb+>=3.6; falls back to syncexecjpre36 on older
syncexecjt:{[query;servertype;joinfunction;timeout] ...}

// [query; servertype; joinfunction]
// syncexecjpre36: send async to all backends, flush, then block on each handle
syncexecjpre36:{[query;servertype;joinfunction] ...}

// Aliases chosen at load time based on .z.K
syncexecj:$[.z.K<3.6; syncexecjpre36; syncexecjt[;;;0Wn]]
syncexec:$[.z.K<3.6; syncexecjpre36[;;raze]; syncexecjt[;;raze;0Wn]]
```

### Server Routing Logic

`getserverids[servertype]` resolves the servertype argument:
- If symbol list: looks up matching server IDs in `.gw.servers` 
- If dict (attributes): calls `getserversindependent` which finds minimum set of servers needed to cover all attribute requirements independently

`getserversindependent[req;att;besteffort]` uses a greedy coverage algorithm — sorts servers by how many requirements they satisfy, removes redundant overlapping servers.

### EOD Handling

```q
// Called by WDB at EOD start
reloadstart:{
  .gw.seteod[1b];                           // block new multi-server queries
  // Find queries not yet returned that span multiple servers
  qids:exec queryid from .gw.queryqueue where ...;
  // Send error to each affected client
  .gw.sendclientreply[;errorprefix,"query did not return prior to eod reload";0b] each qids;
  .gw.finishquery[qids;1b;0Ni];
  }

// Called by WDB when HDB reload is complete
reloadend:{
  .gw.seteod[0b];                           // re-enable queries
  // Refresh attributes from all connected servers
  setattributes .' flip value flip select procname,proctype,...attributes... from .servers.SERVERS;
  .gw.runnextquery[];                       // flush any queued queries
  }
```

### Handler Setup

```q
// gateway.q lines 523-528
.dotz.set[`.z.pc; {x@y; .gw.pc[y]}   @ [value;.dotz.getcommand[`.z.pc];{{[x]}}]];
.dotz.set[`.z.po; {x@y; .gw.po[y]}   @ [value;.dotz.getcommand[`.z.po];{{[x]}}]];
.dotz.set[`.z.pg; {.gw.pgs[.z.w;1b]; x@y} @ [...]];  // 1b = sync
.dotz.set[`.z.ps; {.gw.pgs[.z.w;0b]; x@y} @ [...]];  // 0b = async
// Also wraps .z.ws if already defined
```

`pgs[handle;issync]` updates `.gw.call` dict — used by `asyncexecjpts` and `syncexecjpre36` to verify the correct function is used for the call type.

### Timer Functions (set up at end of gateway.q)

```q
.timer.repeat[...;0D00:05;   (`.gw.removequeries;.gw.querykeeptime); "Remove old queries"]
.timer.repeat[...;0D00:00:05;(`.gw.checktimeout;`);                  "Timeout queries"]
.timer.repeat[...;0D00:05;   (`.gw.removeinactive;.gw.clearinactivetime); "Remove inactive"]
```

### Config Variables

```q
.gw.synccallsallowed:0b          // allow sync calls (default off for performance)
.gw.querykeeptime:0D00:30        // how long to keep completed queries in queue
.gw.errorprefix:"error: "        // prefix on error messages returned to clients
.gw.permissioned:0b              // require .pm.allowed check
.gw.clearinactivetime:0D01:00    // remove inactive client records after 1hr
```

---

## 3. Process Discovery Protocol

Source: `code/processes/discovery.q`, `code/handlers/trackservers.q`

### Registration Sequence

**At every process startup** (`trackservers.q:startup`):

1. Read `process.csv` → `procstab` 
2. If `DISCOVERYREGISTER` or `CONNECTIONSFROMDISCOVERY`: register discovery entries, call `retrydiscovery[]`
3. `retrydiscovery[]` opens connections to all discovery services in the SERVERS table, then sends async `(`..register;\`)` to each
4. If `CONNECTIONSFROMDISCOVERY`: call `registerfromdiscovery[CONNECTIONS;0b]` → queries discovery for known process types
5. If not `CONNECTIONSFROMDISCOVERY`: call `register[procs;proctype;0b]` for each required type from process.csv

**On discovery service side** (`discovery.q:register`):

```q
register:{
  .servers.addw .z.w;           // add caller to SERVERS table (calls addhw[`])
  // De-duplicate: close old handle if same hpup re-registers
  if[count toclose:...];
  // Publish update to all subscribed processes
  new:select proctype,procname,hpup,attributes from .servers.SERVERS where w=.z.w;
  (neg ((where ...)inter key .z.W) except .z.w)@\:(`.servers.procupdate;new);
  }
```

**`addhw[hpup;handle]`** (`trackservers.q:139`):
1. Calls `.servers.getdetails[]` on the remote process to get `procname`, `proctype`, `port`, `attributes`
2. Inserts row into `.servers.SERVERS`

### `.servers.SERVERS` Table Schema

```
Column      Type        Description
----------- ----------- -------------------------------------------
procname    symbol      Process name (e.g., `rdb1)
proctype    symbol      Process type (e.g., `rdb)
hpup        symbol      Host:port connection string (e.g., `:host:5011)
w           int         Open handle (0Ni if disconnected)
hits        int         Number of times handle used via updatestats
startp      timestamp   Time handle was first opened (0Np if not connected)
lastp       timestamp   Time handle was last used
endp        timestamp   Time handle was closed (0Np if still active)
attributes  dict        Process-reported attributes dict from .proc.getattributes[]
```

Source: `trackservers.q:10`

### Reconnection Logic

Two timer-driven retry mechanisms:

```q
// Retry all dead non-discovery connections every RETRY interval (default 5 min)
if[RETRY > 0; .timer.repeat[...;RETRY;(`.servers.retry;`);"Attempt reconnections..."]]

// Retry discovery specifically every DISCOVERYRETRY interval (default 5 min)
if[DISCOVERYRETRY > 0; .timer.repeat[...;DISCOVERYRETRY;(`.servers.retrydiscovery;`);...]]
```

`retry[]` calls `retryrows` on all rows where handle is dead and proctype != `` `discovery ``.
`retrydiscovery[]` handles discovery specifically, then calls `registerfromdiscovery` to refresh known processes.

### When Discovery is Unavailable

- If `DISCOVERYREGISTER:0b` and `CONNECTIONSFROMDISCOVERY:0b`: process reads connections statically from process.csv only — fully offline mode
- If discovery goes down mid-session: `DISCOVERYRETRY` timer attempts to reconnect; existing connections in `.servers.SERVERS` still work
- The gateway blocks in a `while` loop at startup until at least one discovery connection is available (if `DISCOVERYREGISTER:1b`): `gateway.q:535-540`
- `autodiscovery` function on each process is called by discovery when it restarts, triggering `retrydiscovery[]`

### Process Attributes

Override `.proc.getattributes` to publish attributes to discovery:

```q
.proc.getattributes:{[]
  `date`tables!(rdbpartition;tables`.)}
```

The gateway uses these for intelligent routing (e.g., route to HDB that has the required date range).

---

## 4. EOD Event Sequence

Sources: `tickerplant.q`, `rdb.q`, `wdb.q`, `gateway.q`

### Complete EOD Timeline

```
T=EOD time (from .eodtime.nextroll)

TP: .z.ts fires → calls endofday[]
  TP: calls .u.end[] → publishes final batch of data
  TP: calls endofday on each subscriber (RDB and WDB): async `endofday[date]`
  TP: increments date, opens new log file

RDB: receives endofday[date]
  RDB: .rdb.endofday[date;processdata]
    if reloadenabled:
      store row counts in eodtabcount
      notify gateway of updated attributes (async)
      return (WDB will call reload[] later)
    else:
      call .rdb.writedown[hdbdir; date]
        sort each table (.sort.sorttab)
        save to HDB: .Q.en[hdbdir; table] → .Q.par[hdbdir;date;tablename]
      notify HDBs: send (`reload;date) to each
      call .save.postreplay[hdbdir;date]
      reset timeout

WDB: receives endofday[date] (if in saveandsort or save mode)
  WDB: .wdb.endofday[pt;processdata]
    endofdaysave[savedir;pt]  — flush remaining in-memory rows to temp partition
    if saveandsort: endofdaysort[savedir;pt;...] OR endofdaymerge[...] for partbyattr modes
      sort tables using .sort.sorttab (possibly with peach on .z.pd worker processes)
      movetohdb[savedir;hdbdir;pt]  — rename temp partition to HDB
      .save.postreplay[hdbdir;pt]
      if permitreload: doreload[pt]
        informgateway(`reloadstart;`)  — gateway blocks new multi-server queries
        getprocs[pt] each reloadorder  — send reload message to each HDB/RDB/IDB
        wait for all callbacks or eodwaittime timeout
        flushend[]
          informgateway(`reloadend;`)  — gateway re-enables queries, refreshes attributes
    increment currentpartition::pt+1

HDB: receives (`reload;date)
  HDB: load[hdbpath]  — reloads entire HDB from disk

Gateway: receives reloadstart
  .gw.seteod[1b]
  sends timeout errors to any in-flight multi-server queries

Gateway: receives reloadend
  .gw.seteod[0b]
  refreshes server attributes
  .gw.runnextquery[]
```

### Extension Pattern: Custom EOD Hooks

**Option 1 — Post-writedown hook (runs after all tables saved, before HDB reload):**
```q
// In your proctype.q settings file or process code:
.save.postreplay:{[hdbdir;date]
  .lg.o[`postreplay;"custom EOD work for ",string date];
  // your work here
  }
```

**Option 2 — Table manipulation before save:**
```q
// Manipulate table before it is written
.save.savedownmanipulation:enlist[`trade]!enlist {[t]
  // t is the table data; return modified version
  select from t where size>0
  }
```

**Option 3 — Override `endofday` itself (advanced):**
```q
// Wrap the existing function
.rdb.endofday_orig:.rdb.endofday;
.rdb.endofday:{[date;processdata]
  .lg.o[`eod;"custom pre-EOD logic"];
  // ... custom work ...
  .rdb.endofday_orig[date;processdata];
  .lg.o[`eod;"custom post-EOD logic"];
  }
endofday:.rdb.endofday;  // must re-assign root alias
```

### RDB Reload Mode (for WDB-managed RDB)

When `.rdb.reloadenabled:1b` (typically when WDB is used):
1. RDB at EOD stores row counts per table in `eodtabcount` dict
2. RDB does NOT write to disk — returns immediately
3. WDB calls `reload[date]` on RDB after HDB is updated
4. `reload[]` drops the first `eodtabcount[t]` rows from each table (old data)
5. This keeps the RDB running without a full restart

---

## 5. Config Layering — Common Mistakes

**Mistake 1 — Not using guard pattern:**
```q
// WRONG — this will be overwritten by config files
.myns.myvar:100

// CORRECT — this preserves any value set earlier  
.myns.myvar:@[value;`.myns.myvar;100]
```

**Mistake 2 — Setting config after startup:**
```q
// If you set a var in a process code file that loads AFTER config,
// you will overwrite what was in the config file.
// Config loads BEFORE process code.
// Use guard pattern in process code too.
```

**Mistake 3 — Wrong config file location:**
```q
// File must be at $KDBAPPCONFIG/settings/myproctype.q
// NOT at $KDBAPPCONFIG/myproctype.q
// NOT at $KDBCONFIG/myproctype.q (unless you want it to apply to all app deployments)
```

**Mistake 4 — Command-line override syntax:**
```bash
# Correct: full dot-path with leading dash
q torq.q ... -.servers.HOPENTIMEOUT 5000 -.rdb.reloadenabled 1

# Wrong: without leading dot
q torq.q ... -HOPENTIMEOUT 5000
```

**Mistake 5 — parentproctype confusion:**
```
parentproctype code/config loads BEFORE proctype code/config.
If sort process uses -parentproctype wdb, it gets:
  config: settings/wdb.q then settings/sort.q
  code: code/wdb/ then code/sort/
```
```

---