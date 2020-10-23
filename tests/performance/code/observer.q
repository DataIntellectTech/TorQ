// REDO DIS

// function to get all the above stats together:
// takes in [timingtp or timingstp or timingdatatp or timingdatastp; name choice of timing csv; name choice of msg count csv]
.observer.getstats:{[tab;name1;name2]
  // get middle 30 seconds of data as the sample
  t:select from tab where time within ((((first tab)`time)+15000000000);((first tab)`time)+45000000000);
  // get tp -> consumer and feed -> consumer times
  midtimes:value exec feedtotp,tptoconsumer,feedtoconsumer from t;
  medians:`timespan$med each midtimes;
  averages:`timespan$avg each midtimes;
  maximums:`timespan$max each midtimes;
  // drift calculation
  top:(floor (count tab)*.10)#tab;           // get first 10% of sample
  bot:(neg floor (count tab)*.10)#tab;       // get last 10% of sample  
  medtop:`timespan$med each exec feedtotp,tptoconsumer,feedtoconsumer from top;
  medbot:`timespan$med each exec feedtotp,tptoconsumer,feedtoconsumer from bot;
  drift:medtop-medbot;
  statstime:`med`avg`max`drift,'3 cut medians,averages,maximums,value drift;
  // get number of messages stats in mid 30 seconds sample
  seconds:1_select count i by time.second from t;
  maxmps:max seconds;         // max messages per second
  medmps:med seconds;         // median messages per second
  avgmps:avg seconds;         // average messages per second
  totalmsg: count t;          // total messages sent in middle 30 seconds sample
  // set tables of statistics
  `returntab1 set `stat xkey flip (`stat`feedtotp`tptoconsumer`feedtoconsumer)!flip statstime;
  `returntab2 set flip (`totalmsg`maxmps`medmps`avgmps)!totalmsg,value each (maxmps;medmps;avgmps);
  // save stats tables
  save `:returntab1.csv;
  save `:returntab2.csv;
  // move and rename stats tables
  if[not `timingstats in key`:.;system"mkdir timingstats"];
  system["mv returntab1.csv ","timingstats/",string[name1],".csv"];
  system["mv returntab2.csv ","timingstats/",string[name2],".csv"];
 };

/ Need to figure out vanilla TP still

// Do an initial run to kick things off
.observer.startrun:{
  .lg.o[`startrun;"Beginning performance test run."]
  .observer.completed:();
  .observer.run . first .observer.scenarios;
 };

// Run each test scenario
.observer.run:{[batch;mode]
  .lg.o[`run;"Running tests with a ",string[batch]," tickerplant and ",string[mode]," message publishing mode."];

  // Initialise the feed and consumer processes and, if necessary, the STP (vanilla TP doesn't need setting up)
  neg[.observer.feedhandle] @/: ((set;`.feed.bulkrows;.observer.bulkrows);(`.feed.init;mode;batch);(::));
  neg[.observer.conshandle] @/: ((set;`.consumer.bulkrows;.observer.bulkrows);(`.consumer.init;mode;batch);(::));
  if[not `vanilla~batch;neg[.observer.stphandle] @/: ((`init;batch);(::))];

  // Tell the feed to start publishing and add to the list of completed scenarios
  neg[.observer.feedhandle] @/: ((`.feed.run;::);(::));
  .observer.completed,:enlist batch,mode;
 };

// When the feed finishes publishing, it will signal this function to run
.observer.runcomplete:{
  .lg.o[`runcomplete;"Collecting data"];

  // Gather and clear data from the consumer, then run the next test if there is one
  system "sleep 1";
  .observer.results,:.observer.conshandle(`.consumer.results);
  .observer.conshandle(`.consumer.cleartable;::);
  $[count sc:.observer.scenarios except .observer.completed;
    .observer.run . first sc;
    .lg.o[`runcomplete;"Performance test complete."]
    ];
 };

// Set handle from procfile, open handles to feed, consumer and STP
.observer.init:{
  .lg.o[`init;"Setting up process..."];
  .proc.readprocfile .proc.file;
  .servers.startup[];
  .observer.feedhandle:.servers.gethandlebytype[`feed;`any];
  .observer.conshandle:.servers.gethandlebytype[`consumer;`any];
  .observer.stphandle:.servers.gethandlebytype[`segmentedtickerplant;`any];
  };

// Call init function & begin tests if autorun mode is on
.observer.init[];
if[.observer.autorun;.observer.startrun[]];