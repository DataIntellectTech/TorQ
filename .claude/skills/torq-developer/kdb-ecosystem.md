# kdb+ Ecosystem Integration Reference

## 1. PyKX — Python/kdb+ Integration

Source: https://code.kx.com/pykx/

### Modes of Operation

PyKX supports four distinct operating modes:

| Mode | Description |
|---|---|
| **Embedded q** | Run q code directly within the Python process |
| **IPC client** | Connect to a remote kdb+ process from Python |
| **Embedded Python (q→Python)** | Call Python from within a running q process |
| **Server mode** | PyKX exposes a Python process as a kdb+-queryable service |

### IPC Connection Pattern

```python
import pykx as kx

# Connect to a running kdb+ process
with kx.SyncQConnection(host='localhost', port=5000, username='admin', password='admin') as q:
    # Execute q code
    result = q('select from trade where date=.z.d')
    
    # Call a q function
    result = q('.gw.syncexec', kx.CharVector('`$last .z.x'), kx.SymbolAtom('rdb'))
    
    # Convert to pandas
    df = result.pd()

# Async connection
async with kx.AsyncQConnection(host='localhost', port=5000) as q:
    result = await q('1+1')
```

### Type Mapping (Python → kdb+)

| Python | kdb+ | PyKX class |
|---|---|---|
| `int` | long (-7h) | `kx.LongAtom` |
| `float` | float (-9h) | `kx.FloatAtom` |
| `str` | symbol (-11h) | `kx.SymbolAtom` |
| `str` | char vector (10h) | `kx.CharVector` |
| `bool` | boolean (-1h) | `kx.BooleanAtom` |
| `datetime.date` | date (-14h) | `kx.DateAtom` |
| `datetime.datetime` | timestamp (-12h) | `kx.TimestampAtom` |
| `list` | mixed list (0h) | `kx.List` |
| `numpy.ndarray` | typed vector | `kx.LongVector` etc |
| `pandas.DataFrame` | table (98h) | `kx.Table` |
| `pandas.Series` | vector | typed vector |
| `dict` | dictionary (99h) | `kx.Dictionary` |
| `None` | null | type-dependent null |

### Embedded q Pattern (Python runs q in-process)

```python
import pykx as kx

# Execute q expressions
result = kx.q('1+1')              # returns kx.LongAtom(2)
result = kx.q('{x+y}', 1, 2)     # call with args

# Access q namespaces
print(kx.q('.z.p'))               # current timestamp

# Convert to Python types
val = int(kx.q('42'))
df = kx.q('([]a:1 2 3; b:4 5 6)').pd()

# Load q files
kx.q.system.load('/path/to/myfile.q')
```

### Known Limitations / Failure Modes

1. **Symbol pollution**: Converting large Python string lists to kx.SymbolVector interns all strings into the q symbol table permanently — use `CharVector` for high-cardinality strings.
2. **Large table transfers**: Serialization overhead for large tables. Profile with `-8!` byte size before transfer.
3. **Attribute loss**: Attributes (`g#`, `p#` etc.) are not preserved through Python round-trips.
4. **Enumeration handling**: Enum columns are automatically de-enumerated to symbols on IPC transmission.
5. **Null handling**: q nulls map to Python `None` / pandas `NaN`; be careful with downstream type assumptions.
6. **Thread safety**: PyKX connections are not thread-safe — use one connection per thread or use connection pools.
7. **Timeout**: Default connection has no timeout — always set `timeout=` parameter in production.

---

## 2. embedPy (Python within q)

### Loading embedPy

```q
// Load embedPy in a q session
\l p.q

// Or via command line
q p.q myfile.q
```

### Calling Python from q

```q
// Import Python modules
np:.p.import`numpy
pd:.p.import`pandas

// Call Python functions
arr:np[`:array][1 2 3 4 5]
result:np[`:mean][arr]

// Convert between types
pylist:.p.py 1 2 3 4 5    // q list → Python list
qlist:.p.q pylist           // Python list → q list

// Execute Python code string
.p.e "import datetime; x = datetime.date.today()"

// Get Python variable
today:.p.get`x
```

### Common embedPy Patterns

```q
// Use pandas for complex manipulations
pd:.p.import`pandas
df:pd[`:DataFrame][.Q.en[`:hdb;select from trade where date=.z.d]]
grouped:df[`:groupby]["sym"][`:agg][.p.py{`size`sum!("count";"sum")}]

// Scikit-learn model
sklearn:.p.import`sklearn.linear_model
model:sklearn[`:LinearRegression][]
model[`:fit][features;targets]
predictions:model[`:predict][newfeatures]
```

---

## 3. REST/HTTP Integration

Source: https://code.kx.com/q/kb/http/

### Implementing a REST Endpoint in kdb+

```q
// .z.ph — HTTP GET handler
// x = string of entire HTTP request
.z.ph:{
  // Parse the URL and query string
  url:first "?" vs x;
  params:(!). flip "==" vs/: "&" vs last "?" vs x;
  
  // Route based on URL path
  path:1_ url;
  result:$[
    path~"trade"; .j.j select from trade where date=.z.d;
    path~"quote"; .j.j select from quote where date=.z.d;
    // 404
    .h.hn["404 Not Found"; "text/plain"; "unknown endpoint: ",path]
    ];
  .h.hn["200 OK"; "application/json"; result]
  }

// .z.pp — HTTP POST handler
.z.pp:{
  // x contains headers + body
  body:last "\r\n\r\n" vs x;
  data:.j.k body;   // parse JSON body
  // process data...
  .h.hn["200 OK"; "application/json"; .j.j `status`msg!(`ok;"processed")]
  }
```

### JSON Utilities

```q
.j.j x    // q value → JSON string
.j.k x    // JSON string → q dict/table

// Pitfalls:
// .j.j on a symbol list gives ["a","b"] (JSON array of strings)
// .j.j on a table gives [{"col1":val,...}, ...]
// Timestamps become strings: .j.j 2024.01.01D00:00:00 → "2024-01-01T00:00:00.000000000"
// Nulls: .j.j 0N → "null" ; .j.j 0n → "null"
// Long vs float: .j.j 42 → "42" ; .j.j 42.0 → "42.0"
```

### JSON Edge Cases

```q
// Round-trip loss: JSON has no symbol type
// .j.k (.j.j `a`b`c) → ("a";"b";"c")  (strings, not symbols)

// Null handling
.j.j (0N;0n;0Nd)   // "null","null","null" — type information lost

// Large integer precision
// JavaScript JSON.parse loses precision on longs > 2^53
// Consider string-encoding large IDs

// Nested tables
.j.j ([]a:1 2; b:(1 2;3 4))  // nested arrays — complex round-trip
```

### .z.ph Security Considerations

```q
// Default .z.ph evaluates arbitrary q — DANGEROUS in production
// Always override with restricted handler

// Restrict by user
.z.ph:{
  if[not .z.u in `admin`readonly; .h.hn["403 Forbidden";"text/plain";"access denied"]];
  // ... safe handler
  }

// Use .z.ac for HTTP authentication (LDAP, OAuth2, OpenID Connect)
.z.ac:{[x] ...}  // x = (headerdict; requestbody)
```

### HTTP Client (outbound requests)

```q
// GET request
result:.Q.hg `$":http://api.example.com/data"

// POST request  
result:.Q.hp[`$":http://api.example.com/data"; "application/json"; .j.j mydata]

// Low-level (returns bytes)
h:hopen `$":http://api.example.com"
h "GET /data HTTP/1.1\r\nHost: api.example.com\r\n\r\n"
```

---

## 4. WebSocket Integration

Source: https://code.kx.com/q/kb/websockets/

### Server-Side WebSocket Handler

```q
// Start q with port: q myfile.q -p 5000

// Basic echo server
.z.ws:{neg[.z.w] x}

// JSON pub/sub pattern
.z.wo:{[h]  // on WebSocket open
  `wsclients upsert (h; .z.p)
  }

.z.wc:{[h]  // on WebSocket close
  delete from `wsclients where handle=h;
  delete from `wssubs where handle=h;
  }

.z.ws:{[msg]  // on message received
  req:.j.k msg;
  $[req[`type]~"subscribe";
    // register subscription
    [`wssubs upsert (.z.w; req`tables; req`syms)];
    req[`type]~"query";
    // execute query and return result
    [result:@[value;req`query;{`error`msg!(`error;x)}];
     neg[.z.w] -8! .j.j result];  // -8! = serialize to bytes for WS
    // unknown
    neg[.z.w] -8! .j.j `error`msg!(`unknown;"unknown message type")
    ]
  }

// Publish to all subscribers
pubws:{[table;data]
  subs:select handle from wssubs where table in tables;
  msg:.j.j (`type`table`data!(`update;table;data));
  (neg each exec handle from subs) @\: -8! msg;
  }
```

### WebSocket Message Format

```q
// Messages arrive as:
// - byte vectors (-8h type): serialized kdb+ (use -9! to deserialize)
// - char vectors (10h type): text/JSON (use .j.k to parse)

.z.ws:{[x]
  msg:$[-8h=type x; -9!x; .j.k x];  // handle both formats
  ...
  }
```

### Client-Side WebSocket (kdb+ as client, v3.2+)

```q
// Connect to WebSocket server
// Returns (handle; HTTP_response_string)
r:(`$":ws://localhost:5001/stream")"GET / HTTP/1.1\r\nHost: localhost:5001\r\n\r\n"
h:r 0

// Send message
neg[h] .j.j `type`query!(`subscribe;"trade")

// Receive: set .z.ws before connecting
.z.ws:{[x] 0N! "Received: ", string x}
```

### TorQ WebSocket Integration

TorQ wraps `.z.ws` via `.dotz.set` if it's already defined (gateway.q line 528):
```q
if[@[{value x;1b};`.z.ws;{0b}];
  .dotz.set[`.z.ws;{.gw.pgs[.z.w;0b]; x@y} value .dotz.getcommand[`.z.ws]]];
```
This tracks WebSocket connections as async clients in `.gw.call`.

---

## 5. Grafana / AquaQ kdb+ Datasource

### Query Contract

The AquaQ kdb+ Grafana datasource (plugin ID: `aquaqanalytics-kdbbackend-datasource`) connects directly to a kdb+ process via IPC and calls a configured q function.

Standard patterns for Grafana-compatible kdb+ functions:

```q
// Time-series query: returns table with `time` and value columns
// Grafana passes: (starttime; endtime; interval; params)
grafanaTimeseries:{[starttime;endtime;interval;params]
  select time, price from trade 
  where date within `date$(starttime;endtime),
        sym=params`sym
  }

// Table query: returns plain table
grafanaTable:{[starttime;endtime;interval;params]
  select sym, avg price, sum size 
  from trade 
  where date within `date$(starttime;endtime)
  by sym
  }
```

### Function Contract Requirements

1. Must return a table
2. For time-series panels: table must have a `time` column (timestamp type)
3. For table panels: any column structure
4. Function must handle null params gracefully

### Exposing through TorQ Gateway

```q
// In gateway-accessible process (HDB or RDB)
.proc.getattributes:{[] `tables!enlist tables`.}

// Grafana-facing query function on HDB
grafanaQuery:{[starttime;endtime;interval;params]
  tbl:params`table;
  if[not tbl in tables`.; '"table not found: ",string tbl];
  ?[tbl; 
    enlist (within; `date; enlist `date$(starttime;endtime));
    0b; 
    ()]
  }

// Call through gateway (from Grafana → Gateway → HDB)
// Configure datasource to call: .gw.syncexec[("grafanaQuery";starttime;endtime;interval;params);`hdb]
```

---

## 6. C API / C Extensions

### Use Cases

- High-performance feedhandlers (C++ with kdb+ C API)
- Custom compression/decompression
- Integration with low-latency market data feeds (e.g., Solace, LBM)
- FPGA/hardware interface

### Basic Pattern

```c
// Link against k.h from code.kx.com
#include "k.h"

// Open connection
I handle = khpun("localhost", 5000, "user:pass", 1000);

// Execute query
K result = k(handle, "{x+y}", ki(1), ki(2), (K)0);

// Check for error
if(!result || result->t == -128) { /* error */ }

// Serialize/deserialize
K serialized = b9(-1, result);    // serialize
K deserialized = d9(serialized);  // deserialize

// Decrement reference count
r0(result);
```

### When to Use C API vs PyKX

| Use Case | Recommendation |
|---|---|
| Analytics/data science | PyKX |
| Scripting/automation | PyKX or q |
| Low-latency feedhandler | C API |
| Production system integration | q IPC or PyKX |
| Grafana/monitoring | HTTP/.z.ph or Grafana plugin |
| Bulk data loading | q loader or PyKX |
```