// Pub/sub utilities initially used in Segmented TP process
// Functionality for clients to subscribe to all tables or a subset
// Includes option for subscribe to apply filters to received data
// Replaces u.q functionality

\d .stpps

// List of pub/sub tables, populated on startup
t:`

// Handles to publish all data
subrequestall:enlist[`]!enlist ()

// Handles and conditions to publish filtered data
subrequestfiltered:([]tbl:`$();handle:`int$();filts:();columns:())

// Function to send end of period messages to subscribers - endofperiod defined in client side
endp:{
  (neg allsubhandles[])@\:(`endofperiod;x;y;z);
 };

// Function to send end of day messages to subscribers - endofday defined on client side
end:{
  (neg allsubhandles[])@\:(`endofday;x;y);
 };

// Get all distinct sub handles from subrequestall and subrequestfiltered
allsubhandles:{
  distinct raze union/[value subrequestall;exec handle from .stpps.subrequestfiltered]
  };

// Subscribe to everything
suball:{
  delhandle[x;.z.w];
  add[x];
  :(x;schemas[x]);
 };

// Make a filtered subscription
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

// Publish table data
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

// Remove handle from subrequestall
delhandle:{[t;h]
  @[`.stpps.subrequestall;t;except;h];
 };

// Remove handle from subrequestfiltered
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
  // Grab non-keyed tables from root namespace and store their attributes
  .stpps.t:(tables[] where 98h=type each value each tables[]) except `currlog;
  .stpps.schemas:.stpps.t!value each .stpps.t;

  // Strip attributes from tables and store new schemas and a dictionary of table column names
  {@[x;cols x;`#]} each .stpps.t;
  .stpps.schemasnoattributes:.stpps.t!value each .stpps.t;
  .stpps.tabcols:.stpps.t!cols each .stpps.t;
 };

\d .

// Call closesub function after initial .z.pc call on disconnect
.z.pc:{[f;x] @[f;x;()];.stpps.closesub x} @[value;`.z.pc;{{}}];

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

// Define .ps wrapper functions
.ps.loaded:1b;
.ps.publish:.stpps.pub;
.ps.subscribe:.u.sub;
.ps.init:.stpps.init;
.ps.initialise:{.ps.init[];.ps.initialised:1b};

// Allow a non-kdb+ subscriber to subscribe with strings for simple conditions - return string to subscriber
.ps.subtable:{[tab;syms]
  .lg.o[`subtable;"Received a simple string subscription request."];
  val:.[.u.sub;(`$tab;$[count syms;::;first] `$csv vs syms);{:(`error;"Error: ",x)}];
  $[`error~first val;last val;"Subscription successful!"]
 };

// Allow a non-kdb+ subscriber to subscribe with strings for complex conditions - return string to subscriber
.ps.subtablefiltered:{[tab;filters;columns]
  .lg.o[`subtablefiltered;"Received a complex string subscription request."];
  val:.u.sub[`$tab;1!enlist `tabname`filters`columns!(`$tab;filters;columns)];
  $[`error~first val;"Invalid query parameters provided: ",last val;"Subscription successful!"]
 };