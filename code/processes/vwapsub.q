\d .vwapsub // enter vwapsub namespace

tickerplanttypes:@[value;`tickerplanttypes;`segmentedtickerplant];              // tickerplant types to subscribe to
hdbtypes:@[value;`hdbtypes;`hdb];                                               // hdbtypes to connect to

// datareplay settings
realtime:@[value;`realtime;0b];                                                 // use realtime feed or datareplay. default is 0b (datareplay)
replayinterval:@[value;`replayinterval;0Nn];                                    // interval to run upd at (optional)
timerinterval:@[value;`timerinterval;0D00:10:00.00];                            // interval to run calcvwap at
replaysts:@[value;`replaysts;2026.01.22D01:00:00.00];                           // start time of data to retreive from hdb
replayets:@[value;`replayets;2026.01.23D17:00:00.00];                           // end time of data to retrieve from hdb
requiredprocs:value(`hdbtypes`tickerplanttypes)realtime;                        // required processes
tpcheckcycles:@[value;`tpcheckcycles;0W];                                       // specify the number of times the process will check for requiredprocs
tpconnsleep:@[value;`tpconnsleep;10];                                           // number of seconds between attempts to connect to the source tickerplant

// Add hdb and tickerplant to connections list for TorQ
.servers.CONNECTIONS:tickerplanttypes,hdbtypes,`rdb;

// upd function gets sum of price*size and sum of size by sym
// and adds it to the running total inside the vwap table
// This can be used to calculate current vwap quickly.
upd:{[t;d]
  .dbg.upd:(t;d);
  if[t~`trade;
    `vwap set (`.[`vwap]) + select spts:sum price*size,ssize:sum size by sym from d;
    ];
   .u.pub[`vwap;(`.[`vwap])]
 };

// Calculates vwap at current time and adds it to the vwaptimes table, at time t.
calcvwap:{
  //`vwaptimes insert `time`vwap!(t;(select vwap:spts%ssize by sym from `.[`vwap]));
  select vwap:spts%ssize by sym from `.[`vwap]
 };

// replay data set 
datareplay:{[]
  // Turn off timer
  system"t 0";

  // Block process until all required processes are connected
  .servers.startupdepcycles[requiredprocs;tpconnsleep;tpcheckcycles];

  // Retrieve handle to hdb from TorQ serverlist
  h:first exec w from .servers.SERVERS where proctype in .vwapsub.hdbtypes;

  // whc:(parse"select from t where ex=\"N\"") 2; // example of optional where clause
  
  params: (!) . flip ((`tabs;`trade);
                      (`h;h);
                      (`sts;replaysts);
                      (`ets;replayets);
                      //(`where;whc); // Optional where clause
                      (`replayinterval;replayinterval);
                      (`timer;1b);
                      (`timerinterval;timerinterval);
                      (`timerfunc;`.vwapsub.logvwap));

  // Run datareplay utility using avove parameters
  msgs:.datareplay.tablesToDataStream params;

  // Execute each message.
  value each msgs`msg;
 };

logvwap:{.dbg.log:x;`vwaptimes insert `time`vwap!(x;.vwapsub.calcvwap[]);.u.pub[`vwaptimes;(`.[`vwaptimes])]};

// subscribe to tickerplant types
subscribe:{[]
  // Block process until all required processes are connected
  .servers.startupdepcycles[requiredprocs;tpconnsleep;tpcheckcycles]; 

  if[count s:.sub.getsubscriptionhandles[tickerplanttypes;();()!()];
    .lg.o[`subscribe;"found available tickerplant, attempting to subscribe"];
    .sub.subscribe[`trade;`;0b;0b;first s];
    ];
  .timer.rep[`timestamp$.proc.cd[]+00:00;0Wp;timerinterval;(`logvwapnow;`);0h;"Run logvwapnow at set interval";1b]
  }

\d .

vwap:([sym:`$()]spts:`float$();ssize:`int$());
vwaptimes:([]time:`timestamp$();vwap:());

logvwapnow:{.vwapsub.logvwap[.z.p]};

// set upd function at top level
upd:.vwapsub.upd;

// Perform server discovery
.servers.startup[];

/// use tickerplant or datareplay
/$[.vwapsub.realtime;
/    .vwapsub.subscribe[]; // sub to tickerplant
/    .vwapsub.datareplay[]]; // replay hdb data
