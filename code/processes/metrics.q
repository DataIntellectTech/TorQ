/ schemas for tables
sumstab:([] time:`timestamp$(); sym:`g#`symbol$(); sumssize:`int$(); sumsps:`float$(); sumspricetimediff:`float$());
latest:([sym:`u#`symbol$()] time:`timestamp$(); sumssize:`int$(); sumsps:`float$(); sumspricetimediff:`float$());

\d .metrics

/ load settings
windows:@[value;`windows;0D00:01 0D00:05 0D01];
enableallday:@[value;`enableallday;1b];

\d .

/ define upd to keep running sums
upd:{[t;x]
   / join latest to x, maintaining time col from x, then calc running sums
   r:ungroup select time,sumssize:(0^sumssize)+sums size,sumsps:(0^sumsps)+sum price*size,sumspricetimediff:(0^sumspricetimediff)+sums price*0^deltas[first lt;time] by sym from x lj delete time from update lt:time from latest;
   / add latest values for each sym from r to latest
   latest,::select by sym from r;
   / add records to sumstab for all records in update message
   sumstab,::`time`sym xcols 0!r
 }

/ function to calc twap/vwap
/ calculates metrics for windows in .metrics.windows
metrics:{[syms]
   / allow calling function with ` for all syms
   syms:$[syms~`;exec distinct sym from latest;syms,()];
   / metric calcs
   t:select sym,timediff,vwap:(lsumsps-sumsps)%lsumssize-sumssize,twap:(lsumspricetimediff-sumspricetimediff)%.z.p - time
     / get sums asof time each window ago
     from aj[`sym`time;([]sym:syms) cross update time:.z.p - timediff from ([]timediff:.metrics.windows);sumstab] 
          / join latest sums for each sym
          lj 1!select sym,lsumssize:sumssize, lsumsps:sumsps, lsumspricetimediff:sumspricetimediff from latest;

   / add allday window
   if[.metrics.enableallday;
    if[not all syms in key .metrics.start;.metrics.start::exec first time by sym from sumstab];
    t:`sym`timediff xasc t,select sym,timediff:0Nn,vwap:sumsps%sumssize,twap:sumspricetimediff%.z.p - .metrics.start[sym] from latest where sym in syms];

   t
  
 }

\d .metrics 

/ check for TP connection
notpconnected:{[]
	0 = count select from .sub.SUBSCRIPTIONS where proctype in ((),`segmentedtickerplant), active}

/ get handle for TP & subscribe
subscribe:{
  / get handle
  if[count s:.sub.getsubscriptionhandles[`tickerplant;();()!()];
  subproc:first s;
  / if got handle successfully, subsribe to trade table
  .lg.o[`subscribe;"subscribing to ", string subproc`procname];
  :.sub.subscribe[`trade;`;0b;0b;subproc]]};

/ get subscribed to TP, recover up until now from RDB
init:{
  r:subscribe[];

  / make sure connection to TP was successful, or else wait
  while[notpconnected[];
   / wait 10 seconds
   .os.sleep[10];
   / try again to connect to discovery
   .servers.startup[];
   / try again to subscribe to TP
   r:subscribe[]];

  / check if updates have already been sent from TP, if so recover from RDB
  if[r[`icounts][`trade] > 0;
   / make sure connection is made to RDB
   while[not count s:.sub.getsubscriptionhandles[`rdb;();()!()];.os.sleep[10]];
   / get handle for RDB
   h:exec first w from s;
   .lg.o[`recovery;"recovering ",(string r[`icounts][`trade])," records from trade table on ",string first s`procname];
   / query data from before subscription from RDB
   t:h"select time,sym,size,price from trade where i<",string r[`icounts][`trade];
   .lg.o[`recovery;"recovered ",(string count t)," records"];
   / insert data recovered from RDB into relevant tables
   t:select time,sym,sumssize,sumsps,sumspricetimediff from update sumssize:sums size,sumsps:sums price*size,sumspricetimediff:sums price*time-prev time by sym from t;
   @[`.;`sumstab;:;t];
   @[`.;`latest;:;select by sym from t];
   ];

   / setup empty start dict for use in all day calculation
   start::()!();
 }

\d .

// Define top-level functions to be signalled from STP
endofday:{[date;data] .lg.o[`endofday;"End of day received for ",string date]};
endofperiod:{[currp;nextp;data] .lg.o[`endofperiod;"End of period received for current - ",string[currp]," next - ",string nextp]};

/ get connections to TP, & RDB for recovery
.servers.CONNECTIONS:`rdb`tickerplant;
.servers.startup[];
/ run the initialisation function to get subscribed & recover
.metrics.init[];
