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
  if[11=type y;selfiltered[x;y]];
  if[99=type y;addfiltered[x;y]];
  :(x;schemas[x]);
 };

// Add handle to subscriber in sub all mode
add:{
  if[not (count subrequestall x)>i:subrequestall[x]?.z.w;
    subrequestall[x],:.z.w];
 };

// Add handle to subscriber in sub filtered mode
// Where clause and column filters are parsed before adding to subrequestfiltered table
addfiltered:{[x;y]
  filts:$[null y[x]`filts;();enlist parse string y[x]`filts];
  columns:$[null y[x]`columns;();c!c:raze parse string y[x]`columns];
  `.stpps.subrequestfiltered upsert (x;.z.w;filts;columns);
 };

// Add handle for subscriber using old API (filter is list of syms)
selfiltered:{[x;y]
  filts:enlist (in;`sym;enlist y);
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

.z.pc:{[f;x]
   @[f;x;()]; closesub x;
   if[.sctp.tph=x; .lg.e[`.z.pc;"lost connection to tickerplant : ",string .sctp.tickerplantname];exit 0]
   }@[value;`.z.pc;{{}}];

\d .

// Function called on subscription
// Subscriber will call with null y parameter in sub all mode
// In sub filtered mode, y will contain tables to subscribe to and filters to apply
.u.sub:{[x;y]
  if[not x in .stpps.t;
    .lg.e[`rdb;m:"Table ",string[x]," not in list of stp pub/sub tables"];
    :(x;m)
  ];
  if[y~`;:.stpps.suball[x]];
  if[not y~`;:.stpps.subfiltered[x;y]]
 };
