// Pub/sub utilities for segmented tp process
// Functionality for clients to subscribe to all tables or a subset
// Includes option for subsrcibe to apply filters to received data

\d .stpps

// List of pub/sub tables, populated on startup
t:`

// Handles to publish all data
subrequestall:enlist[`]!enlist ()

// Handles and conditions to publish filtered data
subrequestfiltered:([]tbl:`$();handle:`int$();filts:();columns:())

// Function to send end of period messages to subscribers
// Assumes that endofperiod has been defined on the client side in top level namespace
endp:{
  (neg allsubhandles[])@\:(`endofperiod;x;y;z);
 };

// Function to send end of day messages to subscribers      
// Assumes that endofday has been defined on the client side in top level namespace
end:{
  (neg allsubhandles[])@\:(`endofday;x;y);
 };

allsubhandles:{distinct raze union/[value subrequestall;exec handle from .stpps.subrequestfiltered]}

suball:{
  delhandle[x;.z.w];
  add[x];
  :(x;schemas[x]);
 };

subfiltered:{[x;y]
  delhandlef[x;.z.w];
  val:![11 99h;(selfiltered;addfiltered)][type y] . (x;y);
  $[all raze null val;(x;schemas[x]);val]
 };

// Add handle to subscriber in sub all mode
add:{
  if[not (count subrequestall x)>i:subrequestall[x]?.z.w;
    subrequestall[x],:.z.w];
 };

// Parse columns and where clause from keyed table, run test query and add to subrequestfiltered table if it passes
addfiltered:{[x;y]
  filters:$[all null y[x;`filters];();parse each csv vs y[x;`filters]];
  columns:$[all null y[x;`columns];();c!c:parse each csv vs y[x;`columns]];
  if[`error~first test:.[?;(.stpps.schemas[x];filters;0b;columns);{(`error;x)}];
    .lg.e[`addfiltered;"Invalid query parameters provided: ",last test];
    :test
   ];
  `.stpps.subrequestfiltered upsert (x;.z.w;filters;columns);
 };

// Add handle for subscriber using old API (filter is list of syms)
selfiltered:{[x;y]
  filts:enlist (in;`sym;enlist y);
  if[`error~first test:.[?;(.stpps.schemas[x];filts;0b;());{(`error;x)}];
    .lg.e[`addfiltered;"Invalid query parameters provided: ",last test];
    :test
   ];
  `.stpps.subrequestfiltered upsert (x;.z.w;filts;());
 };

pub:{[t;x]
  if[count x;
    if[count h:subrequestall[t];-25!(h;(`upd;t;x))];
    if[t in subrequestfiltered`tbl;
      {[t;x]data:?[t;x`filts;0b;x`columns];neg[x`handle](`upd;t;data)}
      [t;]each select handle,filts,columns from subrequestfiltered where tbl=t
    ];
  ];
 };

// publish and clear tables
pubclear:{
 .stpps.pub'[x;value each x,:()];
 @[`.;x;:;.stpps.schemasnoattributes[x]];
 }

// Remove handle from subscription meta
delhandle:{[t;h]
  @[`.stpps.subrequestall;t;except;h];
 };

delhandlef:{[t;h]
  delete from  `.stpps.subrequestfiltered where tbl=t,handle=h;
 };

// Remove all handles when connection closed
closesub:{[h]
  delhandle[;h]each t;
  delhandlef[;h]each t;
 };

// Set up table and schema information
init:{
  // Grab tables from root namespace and store their attributes
  .stpps.t:tables[] except `currlog;
  .stpps.schemas:.stpps.t!value each .stpps.t;

  // Strip attributes from tables and store new schemas and a dictionary of table column names
  {@[x;cols x;`#]}each .stpps.t;
  .stpps.schemasnoattributes:.stpps.t!value each .stpps.t;
  .stpps.tabcols:.stpps.t!cols each .stpps.t;
 };

// Call closesub function on disconnect
.z.pc:{[f;x] @[f;x;()]; closesub x}@[value;`.z.pc;{{}}];

\d .

// Function called on subscription
// Subscriber will call with null y parameter in sub all mode
// In sub filtered mode, y will contain tables to subscribe to and filters to apply
.u.sub:{[x;y]
  if[x~`;:.u.sub[;y] each .stpps.t];
  if[not x in .stpps.t;
    .lg.e[`sub;m:"Table ",string[x]," not in list of stp pub/sub tables"];
    :(x;m)
  ];
  $[y~`;.stpps.suball[x];.stpps.subfiltered[x;y]]
 };

// Allow a non-kdb+ subscriber to subscribe with strings for simple conditions - return string to subscriber
subtable:{[tab;syms]
  .lg.o[`subtable;"Received a simple string subscription request."];
  val:.[.u.sub;(`$tab;$[count syms;::;first] `$csv vs syms);{:(`error;"Error: ",x)}];
  $[`error~first val;last val;"Subscription successful!"]
 };

// Allow a non-kdb+ subscriber to subscribe with strings for complex conditions - return string to subscriber
subtablefiltered:{[tab;filters;columns]
  .lg.o[`subtablefiltered;"Received a complex string subscription request."];
  val:.u.sub[`$tab;1!enlist `tabname`filters`columns!(`$tab;filters;columns)];
  $[`error~first val;"Invalid query parameters provided: ",last val;"Subscription successful!"]
 };