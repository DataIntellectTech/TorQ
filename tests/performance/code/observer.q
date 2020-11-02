// REDO DIS

// function to get all the above stats together:
// takes in [timingtp or timingstp or timingdatatp or timingdatastp; name choice of timing csv; name choice of msg count csv]
.observer.getstats:{[tab;scenario]
  // get middle 90% of data as the sample
  tab:select from tab where batching=scenario[0], pubmode=scenario[1];
  looptime:.observer.feedhandle ".feed.looptime";
  t:select from tab where time within ((((first tab)`time)+"v"$0.1*looptime);((first tab)`time)+"v"$0.9*looptime); 
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
  // Rows per update
  multi:?[`bulk=scenario[1];.observer.bulkrows;1];
  // get number of messages stats in mid 30 seconds sample
  seconds:1_select count i by time.second from t;
  maxmps:multi*max seconds;         // max messages per second
  medmps:multi*med seconds;         // median messages per second
  avgmps:multi*avg seconds;         // average messages per second
  totalmsg:multi*count t;          // total messages sent in middle 30 seconds sample
  // set tables of statistics
  `returntab1 set `stat xkey flip (`stat`feedtotp`tptoconsumer`feedtoconsumer)!flip statstime;
  `returntab2 set flip (`totalmsg`maxmps`medmps`avgmps)!totalmsg,value each (maxmps;medmps;avgmps);
  // save stats tables
  statsdir:(getenv `KDBTESTS),"/performance/";
  if[not `timingstats in key `$":",statsdir; system "mkdir ", statsdir, "timingstats"];
  tab1name:`$":",statsdir,"timingstats/",string[scenario[0]],string[scenario[1]],"_",string[.z.p],"_1.csv";
  tab2name:`$":",statsdir,"timingstats/",string[scenario[0]],string[scenario[1]],"_",string[.z.p],"_2.csv";
  if[.observer.savetodisk;hsym[tab1name] 0: csv 0: returntab1];
  if[.observer.savetodisk;hsym[tab2name] 0: csv 0: returntab2];
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
    {.lg.o[`runcomplete;"Generating Performance Stats"];
      .observer.getstats[.observer.results;] each .observer.scenarios;
      .lg.o[`runcomplete;"Performance test complete."]}[]
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
