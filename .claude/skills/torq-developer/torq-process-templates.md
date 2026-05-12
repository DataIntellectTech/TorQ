# TorQ Process Templates

## process.csv Format (Complete)

```csv
host,port,proctype,procname,U,localtime,g,T,w,load,startwithall,extras,qcmd
```

| Column | Required | Description | Example |
|---|---|---|---|
| `host` | Yes | Hostname or `localhost` | `localhost` |
| `port` | Yes | Port number; `{KDBBASEPORT}+N` expands via env vars | `{KDBBASEPORT}+2` |
| `proctype` | Yes | Process type (drives code/config loading) | `rdb` |
| `procname` | Yes | Unique process name | `rdb1` |
| `U` | No | Path to access list file (user:password per line) | `${TORQAPPHOME}/appconfig/passwords/accesslist.txt` |
| `localtime` | No | 1=local time for logs, 0=UTC | `1` |
| `g` | No | GC mode: 1=immediate (safer), 0=deferred (faster) | `1` |
| `T` | No | Query timeout in seconds (0=unlimited) | `180` |
| `w` | No | Max workspace in MB | `4000` |
| `load` | No | File or directory to load | `${KDBCODE}/processes/rdb.q` |
| `startwithall` | No | 1=included in `torq.sh start all` | `1` |
| `extras` | No | Additional command-line parameters | `-s -2 -parentproctype wdb` |
| `qcmd` | No | q executable name (default `q`) | `q` |

### Finance Starter Pack process.csv (reference)

```csv
host,port,proctype,procname,U,localtime,g,T,w,load,startwithall,extras,qcmd
localhost,{KDBBASEPORT}+1,discovery,discovery1,...,1,0,,,${KDBCODE}/processes/discovery.q,1,,q
localhost,{KDBBASEPORT},segmentedtickerplant,stp1,...,1,0,,,${KDBCODE}/processes/segmentedtickerplant.q,1,-schemafile ${TORQAPPHOME}/database.q -tplogdir ${KDBTPLOG},q
localhost,{KDBBASEPORT}+2,rdb,rdb1,...,1,1,180,,${KDBCODE}/processes/rdb.q,1,,q
localhost,{KDBBASEPORT}+3,hdb,hdb1,...,1,1,60,4000,${KDBHDB},1,,q
localhost,{KDBBASEPORT}+4,hdb,hdb2,...,1,1,60,4000,${KDBHDB},1,,q
localhost,{KDBBASEPORT}+5,wdb,wdb1,...,1,1,,,${KDBCODE}/processes/wdb.q,1,,q
localhost,{KDBBASEPORT}+6,sort,sort1,...,1,1,,,${KDBCODE}/processes/wdb.q,1,-s -2 -parentproctype wdb,q
localhost,{KDBBASEPORT}+7,gateway,gateway1,...,1,1,,4000,${KDBCODE}/processes/gateway.q,1,,q
localhost,{KDBBASEPORT}+8,kill,killtick,,1,0,,,${KDBCODE}/processes/kill.q,0,,q
localhost,{KDBBASEPORT}+9,monitor,monitor1,,1,0,,,${KDBCODE}/processes/monitor.q,0,,q
localhost,{KDBBASEPORT}+10,tickerlogreplay,tpreplay1,,1,0,,,${KDBCODE}/processes/tickerlogreplay.q,0,,q
localhost,{KDBBASEPORT}+11,housekeeping,housekeeping1,...,1,0,,,${KDBCODE}/processes/housekeeping.q,1,,q
localhost,{KDBBASEPORT}+12,reporter,reporter1,...,1,0,,,${KDBCODE}/processes/reporter.q,0,,q
localhost,{KDBBASEPORT}+14,feed,feed1,,1,0,,,${KDBAPPCODE}/tick/feed.q,1,,q
localhost,{KDBBASEPORT}+15,segmentedchainedtickerplant,sctp1,...,1,0,,,${KDBCODE}/processes/segmentedtickerplant.q,1,-parentproctype segmentedtickerplant,q
localhost,{KDBBASEPORT}+16,sortworker,sortworker1,,1,1,,,${KDBCODE}/processes/wdb.q,1,-parentproctype wdb,q
localhost,{KDBBASEPORT}+18,metrics,metrics1,...,1,1,,,${KDBAPPCODE}/processes/metrics.q,1,,q
```

Source: TorQ-Finance-Starter-Pack `appconfig/process.csv`

---

## Minimal New Process

```q
// myproc.q — load via: q torq.q -load code/processes/myproc.q -proctype myproc -procname myproc1

\d .myproc

// Config with guard pattern (all overridable from config files or command line)
targetproctype:@[value;`targetproctype;`hdb]
pollinterval:@[value;`pollinterval;0D00:01]

// Main logic
run:{[]
  h:first exec w from .servers.getservers[`proctype;targetproctype;()!();1b;0b];
  if[null h; .lg.w[`run;"no handle to ",string targetproctype]; :()];
  res:@[h;myquery;{.lg.e[`run;"query failed: ",x]}];
  .lg.o[`run;"got ",string count res," rows"];
  }

\d .

// Extend CONNECTIONS to include our target
.servers.CONNECTIONS:distinct .servers.CONNECTIONS,`.myproc.targetproctype

// Register timer
if[@[value;`.timer.enabled;0b];
  .timer.repeat[.proc.cp[];0Wp;.myproc.pollinterval;(`.myproc.run;`);"Poll target process"]];

// Document public function
.api.add[`.myproc.run;1b;"Poll target process and log result count";"[]";"()"];
```

---

## Feedhandler Template

```q
// feedhandler.q
// Start: q torq.q -load code/processes/feedhandler.q -proctype feed -procname feed1

\d .feed

// Config (all overridable)
targettp:@[value;`targettp;`tickerplant]
publishinterval:@[value;`publishinterval;0D00:00:01]
tables:@[value;`tables;`trade`quote]

// Track TP handle
tph:`int$()

// Connect to tickerplant
gettph:{[]
  tph::first exec w from .servers.getservers[`proctype;targettp;()!();1b;1b];
  if[null tph; .lg.w[`gettph;"no tickerplant available"]];
  tph}

// Publish data to TP
publishtrade:{[]
  if[null h:gettph[]; :()];
  data:(enlist .z.p; enlist `AAPL; enlist 150.5; enlist 100i; enlist 0b; enlist " "; enlist "N"; enlist `nasdaq);
  @[neg[h]; (`upd;`trade;flip `time`sym`price`size`stop`cond`ex`src!data); 
    {.lg.e[`publish;"failed to publish: ",x]}]
  }

publishquote:{[]
  if[null h:gettph[]; :()];
  data:(enlist .z.p; enlist `AAPL; enlist 150.4; enlist 150.6; enlist 100; enlist 100; enlist " "; enlist "N"; enlist `nasdaq);
  @[neg[h]; (`upd;`quote;flip `time`sym`bid`ask`bsize`asize`mode`ex`src!data);
    {.lg.e[`publish;"failed to publish: ",x]}]
  }

\d .

// Set CONNECTIONS
.servers.CONNECTIONS:distinct .servers.CONNECTIONS,`.feed.targettp

// Register timers
if[@[value;`.timer.enabled;0b];
  .timer.repeat[.proc.cp[];0Wp;.feed.publishinterval;(`.feed.publishtrade;`);"Publish trade"];
  .timer.repeat[.proc.cp[];0Wp;.feed.publishinterval;(`.feed.publishquote;`);"Publish quote"]];
```

---

## Custom RDB Template

```q
// Custom RDB — load via: q torq.q -load code/processes/rdb.q -proctype myrdb -procname myrdb1
// Or set -parentproctype rdb to inherit standard RDB code and just override

// Override specific settings BEFORE rdb.q is loaded
// (put this in appconfig/settings/myrdb.q)
\d .rdb
ignorelist:`heartbeat`logmsg`myinternaltable   // add to ignore list
gc:1b                                           // enable GC at EOD
reloadenabled:1b                                // use WDB-managed reload
subscribeto:`trade`quote                        // only these tables
\d .

// Post-subscribe hook: runs after subscription is set up
// Put in code/myrdb/ directory or use .proc.addinitlist
.proc.addinitlist {[]
  .lg.o[`init;"custom RDB initialised: subscribed to "," " sv string .rdb.subtables]
  }

// Custom upd hook (root namespace)
upd:{[t;x]
  // Call default insert
  t insert x;
  // Custom: publish count to gateway
  if[t=`trade;
    if[count h:exec w from .servers.getservers[`proctype;`gateway;()!();0b;0b];
      neg[first h] (`.myapp.tradetick; count value t)]
   ]
  }

// Custom EOD post-hook
.save.postreplay:{[hdbdir;date]
  .lg.o[`eod;"custom post-EOD: ",string date];
  // e.g. update a control table, send email
  }
```

---

## Custom WDB Template

```q
// Settings for WDB (appconfig/settings/wdb.q or appconfig/settings/wdb1.q)
\d .wdb
mode:`saveandsort              // saveandsort | save | sort
writedownmode:`default         // default | partbyattr | partbyenum | partbyfirstchar
maxrows:enlist[`]!enlist 500000  // default max rows before writedown (per table)
// or per-table:
// maxrows:`trade`quote!200000 100000
settimer:0D00:00:30            // check row counts every 30s
gc:1b                          // GC after each save
eodwaittime:0D00:00:30         // wait 30s for reload callbacks at EOD
reloadorder:`hdb`rdb           // reload HDBs first, then RDBs
\d .

// Sort configuration (sort.csv)
// Format: tablename,att,sortKey1,sortKey2,...
// trade,p,sym,time      ← parted attribute on sym, sorted by sym then time
// quote,p,sym,time      ← parted attribute on sym, sorted by sym then time
```

---

## Gateway Extension Template

```q
// Gateway extension (put in appconfig/settings/gateway.q or code/gateway/)

// Allow sync calls (disabled by default)
.gw.synccallsallowed:1b

// Enable permissioning
.gw.permissioned:1b

// Extend server connection hook: called when new processes register
.servers.addprocscustom:{[connectiontab;procs]
  // Call default behaviour
  .gw.runnextquery[];
  .gw.addserversfromconnectiontable[.servers.CONNECTIONS];
  // Custom: log new process registration
  .lg.o[`addprocs;"new processes registered: "," " sv string exec procname from connectiontab];
  }

// Extend on-connect hook: runs when gateway connects to a backend
.servers.connectcustom:{[f;connectiontab]
  .gw.addserversfromconnectiontable[.servers.CONNECTIONS];
  f@connectiontab;
  // Custom: refresh attributes
  .lg.o[`connect;"connected to "," " sv string exec procname from connectiontab];
  }@[value;`.servers.connectcustom;{{[x]}}]
```

---

## setenv.sh Template (Full)

```bash
#!/bin/bash
if [ "-bash" = "$0" ]; then
  dirpath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  dirpath="$(cd "$(dirname "$0")" && pwd)"
fi

# TorQ framework location
export TORQHOME=/path/to/TorQ/latest
# Application location (can be same as TORQHOME for simple setups)
export TORQAPPHOME=/path/to/myapp

export KDBCONFIG=${TORQHOME}/config
export KDBCODE=${TORQHOME}/code
export KDBLOGS=${TORQAPPHOME}/logs
export KDBHTML=${TORQHOME}/html
export KDBLIB=${TORQHOME}/lib
export KDBHDB=${TORQAPPHOME}/hdb
export KDBWDB=${TORQAPPHOME}/wdbhdb
export KDBTPLOG=${TORQAPPHOME}/tplogs
export KDBAPPCONFIG=${TORQAPPHOME}/appconfig
export KDBAPPCODE=${TORQAPPHOME}/code
export KDBBASEPORT=6000

# Process CSV location
export TORQPROCESSES=${KDBAPPCONFIG}/process.csv

# Optional: separate DQC/DQE databases
export KDBDQCDB=${TORQAPPHOME}/dqe/dqcdb/database
export KDBDQEDB=${TORQAPPHOME}/dqe/dqedb/database

# q executable path (if not in PATH)
export QCMD=q
export RLWRAP=rlwrap
export QCON=qcon
```

---

## TorQ Project Structure (Full)

```
myapp/
├── appconfig/
│   ├── process.csv              ← Process definitions
│   ├── passwords/
│   │   ├── accesslist.txt       ← user:password entries
│   │   ├── default.txt          ← default outbound connection password
│   │   └── rdb.txt              ← rdb-specific outbound password
│   └── settings/
│       ├── default.q            ← App-wide config overrides
│       ├── rdb.q                ← RDB-specific config
│       ├── hdb.q                ← HDB-specific config
│       ├── gateway.q            ← Gateway-specific config
│       └── rdb1.q               ← Process-name-specific config
├── code/
│   ├── common/                  ← Loaded by all processes
│   │   └── myutilities.q
│   ├── rdb/                     ← Loaded by rdb proctype
│   │   └── customrdb.q
│   ├── hdb/                     ← Loaded by hdb proctype
│   │   └── customhdb.q
│   ├── gateway/                 ← Loaded by gateway proctype
│   │   └── customgw.q
│   └── processes/               ← Process entry-point files
│       └── myfeed.q
├── hdb/                         ← HDB data directory ($KDBHDB)
├── wdbhdb/                      ← WDB temp storage ($KDBWDB)
├── tplogs/                      ← TP log files ($KDBTPLOG)
├── logs/                        ← TorQ log files ($KDBLOGS)
├── database.q                   ← Table schema definitions
└── setenv.sh                    ← Environment setup script
```

---

## TorQ Schema File (database.q)

```q
// FSP example (database.q)
quote:([]time:`timestamp$(); sym:`g#`symbol$(); bid:`float$(); ask:`float$(); 
        bsize:`long$(); asize:`long$(); mode:`char$(); ex:`char$(); src:`symbol$())
trade:([]time:`timestamp$(); sym:`g#`symbol$(); price:`float$(); size:`int$(); 
        stop:`boolean$(); cond:`char$(); ex:`char$(); side:`symbol$())
```

Rules:
- `time` must be first column (`timestamp` type for TP compatibility)
- `sym` must be second column with `` `g# `` attribute
- Passed to TP via `-schemafile database.q` in process.csv extras
- TP validates that all incoming `upd` messages have time+sym as first two columns

---

## sort.csv Format

```csv
tablename,att,sortKey1,sortKey2,...
trade,p,sym,time
quote,p,sym,time
```

| Column | Description |
|---|---|
| `tablename` | Table to configure |
| `att` | Attribute to apply to sort key 1: `p`=parted, `g`=grouped, `u`=unique, `s`=sorted |
| `sortKey1...N` | Columns to sort by (in order) |

---

## Quick Deployment Checklist

- [ ] `setenv.sh` defines all required env vars
- [ ] `process.csv` has correct ports (no conflicts), `startwithall=1` for production processes
- [ ] `appconfig/passwords/accesslist.txt` created with `admin:admin` (or secure equivalent)
- [ ] Schema file (`database.q`) has `time` first, `sym` second, `` `g# `` on sym
- [ ] `sort.csv` configured for all tables
- [ ] `hdb/`, `wdbhdb/`, `tplogs/`, `logs/` directories created
- [ ] All processes in CONNECTIONS list (RDB needs `tickerplant`; gateway needs `rdb`, `hdb`)
- [ ] `.proc.getattributes` overridden on HDB/RDB to expose date/table attributes for gateway routing
- [ ] Timer enabled (`-t 1000` in extras or `system"t 1000"` in code) where required (RDB requires it)
- [ ] EOD hooks (`.save.postreplay`, `.save.savedownmanipulation`) tested against replay
- [ ] Log directory writable by process user
```

---

## Environment Variables

| Variable | Description |
|---|---|
| `KDBCONFIG` | Base configuration directory |
| `KDBCODE` | TorQ code directory |
| `KDBLOGS` | Log file directory |
| `KDBHTML` | HTML files for web interfaces |
| `KDBLIB` | Supporting library files |
| `KDBAPPCONFIG` | Application config directory (overrides KDBCONFIG) |
| `KDBAPPCODE` | Application code directory |
| `KDBBASEPORT` | Base port (FSP default: 6000, processes at KDBBASEPORT+offset) |
| `KDBHDB` | HDB directory |
| `KDBTPLOG` | TP log directory |
| `KDBWDB` | WDB temp storage directory |

---

## Deployment Directory Layout

```
deploy/
├── bin/
│   ├── torq.sh          # Process management script (Linux only)
│   └── setenv.sh        # Sets all env vars; source before torq.sh
├── TorQ/latest/         # TorQ framework (never modify)
│   ├── torq.q
│   ├── code/
│   └── config/
└── TorQApp/latest/      # Application layer
    ├── appconfig/
    │   ├── process.csv
    │   ├── settings/    # App-specific config overrides
    │   └── passwords/   # Connection password files
    └── code/            # App-specific code
```

---

## Config and Code Layering (complete order)

For each of `KDBCONFIG`, `KDBSERVCONFIG`, `KDBAPPCONFIG`:
1. `settings/default.q`
2. `settings/{parentproctype}.q`
3. `settings/{proctype}.q`
4. `settings/{procname}.q`

For code loading, for each of `KDBCODE`, `KDBSERVCODE`, `KDBAPPCODE`:
1. `common/` directory
2. `{parentproctype}/` directory
3. `{proctype}/` directory
4. `{procname}/` directory
5. `handlers/` directories

Then: `-load` file(s) specified on command line.

---

## torq.sh Commands

```bash
./deploy/bin/torq.sh start all              # start all startwithall=1 processes
./deploy/bin/torq.sh stop all               # graceful stop all
./deploy/bin/torq.sh debug rdb1             # start rdb1 in foreground (-debug -nopi)
./deploy/bin/torq.sh qcon rdb1 admin:admin  # qcon into running process
./deploy/bin/torq.sh summary                # show status table
./deploy/bin/torq.sh procs                  # list all processes
./deploy/bin/torq.sh print rdb1             # print startup command line
./deploy/bin/torq.sh top rdb1               # show top.q stats
./deploy/bin/torq.sh stop rdb1 -force       # kill -9
```

---