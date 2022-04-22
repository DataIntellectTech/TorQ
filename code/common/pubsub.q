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
  // Different handling for requests passed in as a sym list or a keyed table
  val:![11 99h;(selfiltered;addfiltered)][type y] . (x;y);
  $[all raze null val;(x;schemas[x]);val]
 };

// Add handle to subscriber in sub all mode
add:{
  if[not (count subrequestall x)>i:subrequestall[x]?.z.w;
    subrequestall[x],:.z.w];
 };

// Error trap function for parsing string filters
errparse:{.lg.e[`addfiltered;m:y," error: ",x];'m};

// Parse columns and where clause from keyed table, spit out errors if any stage fails
addfiltered:{[x;y]
  // Use dummy queries to produce where and column clauses
  filters:$[all null f:y[x;`filters];();@[parse;"select from t where ",f;.stpps.errparse[;"Filter"]] 2];
  columns:last $[all null c:y[x;`columns];();@[parse;"select ",c," from t";.stpps.errparse[;"Column"]]];

  // Run these clauses in a test query, add to table if successful, throw error if not
  @[eval;(?;.stpps.schemas[x];filters;0b;columns);.stpps.errparse[;"Query"]];
  `.stpps.subrequestfiltered upsert (x;.z.w;filters;columns);
 };

// Add handle for subscriber using old API (filter is list of syms)
selfiltered:{[x;y]
  filts:enlist enlist (in;`sym;enlist y);
  @[eval;(?;.stpps.schemas[x];filts;0b;());.stpps.errparse[;"Query"]];
  `.stpps.subrequestfiltered upsert (x;.z.w;filts;());
 };

// Publish table data
pub:{[t;x]
  if[not count x;:()];
  if[count h:subrequestall[t];-25!(h;(`upd;t;x))];
  if[t in .stpps.subrequestfiltered`tbl;
    {[t;x;sels] data:eval(?;x;sels`filts;0b;sels`columns);
         if[count data;neg[sels`handle](`upd;t;data)]}[t;x;]
           each select handle,filts,columns from .stpps.subrequestfiltered where tbl=t
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

// Strip attributes and remove keying from tables and store in separate dictionary (for use on STP and SCTP)
attrstrip:{[t]
  {@[x;cols x;`#]} each .stpps.t:t;
  .stpps.schemasnoattributes:.stpps.t!value each .stpps.t;
 };

// Set up table and schema information
init:{[t]
  if[count b:t where not t in tables[];{.lg.e[`psinit;m:"Table ",string[x]," does not exist"];'m} each b];
  .stpps.t:t except b;
  .stpps.schemas:.stpps.t!value each .stpps.t;
  .stpps.tabcols:.stpps.t!cols each .stpps.t;
 };

\d .

// Call closesub function after initial .z.pc call on disconnect
.z.pc:{[f;x] @[f;x;()];.stpps.closesub x} @[value;`.z.pc;{{}}];

// Function called on subscription
// Subscriber will call with null y parameter in sub all mode
// In sub filtered mode, y will contain tables to subscribe to and filters to apply
.u.sub:{[x;y]
  if[x~`;:.z.s[;y] each .stpps.t];
  if[not x in .stpps.t;
    .lg.e[`sub;m:"Table ",string[x]," not in list of stp pub/sub tables"];
    :(x;m)
  ];
  $[y~`;.stpps.suball[x];.stpps.subfiltered[x;y]]
 };

// Default definition for .u.pub incase process does publishes via .u.pub
.u.pub:.stpps.pub

// Define .ps wrapper functions
.ps.loaded:1b;
.ps.publish:.stpps.pub;
.ps.subscribe:.u.sub;
.ps.init:.stpps.init;
.ps.initialise:{.ps.init[tables[]];.ps.initialised:1b};

// Allow a non-kdb+ subscriber to subscribe with strings for simple conditions - return table name and schema to subscriber
.ps.subtable:{[tab;syms]
  .lg.o[`subtable;"Received a subscription to ",$[count tab;tab;"all tables"]," for ",$[count syms;syms;"all syms"]];
  val:.u.sub[`$tab;$[count syms;::;first] `$csv vs syms];
  $[10h~type last val;'last val;val]
 };

// Allow a non-kdb+ subscriber to subscribe with strings for complex conditions - return table name and schema to subscriber
.ps.subtablefiltered:{[tab;filters;columns]
  .lg.o[`subtablefiltered;"Received a subscription to ",$[count tab;tab;"all tables"]," for filters: ",filters," and columns: ",columns];
  val:.u.sub[`$tab;1!enlist `tabname`filters`columns!(`$tab;filters;columns)];
  $[10h~type last val;'last val;val]
 };

// Striping data in a TorQ Installation
// Limitation: only max 16 (hexidecimal digits 0-9 A-F) processes using this logic
// Can expand beyond 16 processes if required - Modify lookup and modmd5 function to use more digits e.g. "8b" for a single map
.ds.lookup:{[numseg;maxproc]
    hexdg:lower .Q.nA til maxproc;
    seg:til numseg;
    hexdg!maxproc#til numseg
    }[;16]

// Hash function
.ds.modmd5:{first each string first each md5'[string x]}

.ds.map:{[numseg;sym] sym@/:group .ds.lookup[numseg] .ds.modmd5 sym}

// Striping function which stores the mappings for any symbols that it has already computed and 
// for subsequent requests for that symbol, it looks them up
.ds.stripe:{[input;skey]
    // If no updates, return
    if[0=count sym:distinct input;:()];
    // Check if .ds.subreq (dict) exists
    $[`subreq in key`.ds;
        // If .ds.numseg changes - reset .ds.subreq
        [
            if[.ds.numseg<>1+max key .ds.subreq;`.ds.subreq set ()!()];
            // If .ds.subreq exists - check for new sym and append to .ds.subreq
            if[any new:not sym in raze value .ds.subreq;
                `.ds.subreq set .ds.subreq,' .ds.map[.ds.numseg;sym where new];
            ];
        ];
        // Initialize .ds.subreq if does not exists
        `.ds.subreq set .ds.map[.ds.numseg;sym]
    ];
    .ds.subreq skey
    }
