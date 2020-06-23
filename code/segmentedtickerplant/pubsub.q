// Pub/sub utilities for segmented tp process
// Functionality for clients to subscribe to all tables or a subset
// Includes option for subsrcibe to apply filters to received data

/load schema from params, default to "sym.q"
/.proc.loadf[(src:$[`schemafile in key .proc.params;raze .proc.params`schemafile;"sym"]),".q"];

\d .stpps

// List of pub/sub tables, populated on startup
t:`

// Handles to publish all data
subrequestall:enlist[`]!enlist ()

// Handles and conditions to publish filtered data
subrequestfiltered:([tabname:`$()]handle:`int$();filts:`$();columns:`$())

msgcount:enlist[`]!enlist ()

// Function to send end of period messages to subscribers
// Assumes that .u.endp has been defined on the client side
endp:{
  (neg raze union/[value subrequestall;exec handle from .stpps.subrequestfiltered])@\:(`.u.endp;x;y);
 };

// Function to send end of day messages to subscribers      
// Assumes that .u.end has been defined on the client side   
end:{
  (neg raze union/[value subrequestall;exec handle from .stpps.subrequestfiltered])@\:(`.u.endp;x;y);
 };

suball:{
  delhandle[x].z.w;
  :add[x];
 };

subfiltered:{[x;y]
  delhandlef[x].z.w;
  :addfiltered[x;y];
 };

// Add handle to subscriber in sub all mode
add:{
  if[not (count subrequestall x)>i:subrequestall[x;]?.z.w;
    subrequestall[x],:.z.w];
  (x;$[99=type v:value x;v;0#v])
 };

// Add handle to subscriber in sub filtered mode
addfiltered:{[x;y]
  if[not .z.w in subrequestfiltered[x]`handle;
    @[`.stpps.subrequestfiltered;x;:;(enlist[`handle]!enlist .z.w),y[x]]];
  (x;$[99=type v:value x;v;0#v])
 };

pub:{[t;x]
  if[count x;
    if[count h:subrequestall[t];-25!(h;(`upd;t;x))];
    if[t in key subrequestfiltered;
      w:subrequestfiltered[t];
      query:"select ",string[w`columns]," from ",string[t]," where ",string[w`filts];
      x:value query;
      -25!((),w`handle;(`upd;t;x))
    ]
  ]
 };

// Functions to add columns on updates
updtab:enlist[`]!enlist {(enlist(count first x)#.z.p),x}

// Remove handle from subscription meta
delhandle:{[t;h]
  @[`.stpps.subrequestall;t;except;h];
 };

delhandlef:{[t;h]
  delete from  `.stpps.subrequestfiltered where tabname=t,handle=h;
 };

// Remove all handles when connection closed
closesub:{[h]
  delhandle[;h]each t;
  delhandlef[;h]each t;
 };

.z.ts:{
  pub'[t;value each t];
  @[`.;t;@[;`sym;`g#]0#];
  ts .z.p
 };

.z.pc:{[f;x] f@x; closesub x}@[value;`.z.pc;{{}}]

\d .

// Function called on subscription
// Subscriber will call with null y parameter in sub all mode
// In sub filtered mode, y will contain tables to subscribe to and filters to apply
.u.sub:{[x;y]
  if[not x in .stpps.t;'x];
  if[y~`;:.stpps.suball[x]];
  if[not y~`;:.stpps.subfiltered[x;y]]
 };

