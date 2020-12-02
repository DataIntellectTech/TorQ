// Main script for Observer process
// This process orchestrates the performance tests, collects the results and performs post-processing

// Do an initial run to kick things off
.observer.startrun:{
  .lg.o[`startrun;"Beginning performance test run."]
  .observer.completed:();
  .observer.run . first .observer.scenarios;
 };

// Run each test scenario
.observer.run:{[batch;mode]
  .lg.o[`run;"Running tests with a ",string[batch]," tickerplant and ",string[mode]," message publishing mode."];

  // Initialise the feed and consumer processes and the tickerplants
  neg[.observer.feedhandle] @/: ((set;`.feed.bulkrows;.observer.bulkrows);(`.feed.init;mode;batch);(::));
  neg[.observer.conshandle] @/: ((set;`.consumer.bulkrows;.observer.bulkrows);(`.consumer.init;mode;batch);(::));
  if[batch in `defaultbatch`memorybatch`immediate;neg[.observer.stphandle] @/: ((set;`.eodtime.dailyadj;0D00:00:00);(`setup;batch);(::))];
  if[`vanillabatch~batch;.observer.tphandle(system;.observer.tpreset)];
  if[`tickbatch~batch;.observer.kxhandle(system;.observer.tickreset)];
  
  // Tell the feed to start publishing and add to the list of completed scenarios
  neg[.observer.feedhandle] @/: ((`.feed.run;::);(::));
  .observer.completed,:enlist batch,mode;
 };

// When the feed finishes publishing, it will signal this function to run
.observer.runcomplete:{
  // Gather and clear data from the consumer, then run the next test if there is one, if not, begin post-processing
  .lg.o[`runcomplete;"Collecting data"];
  system "sleep 5";
  .observer.results,:.observer.conshandle(`.consumer.results);
  .observer.conshandle(`.consumer.cleartable;::);
  $[count sc:.observer.scenarios except .observer.completed;
    .observer.run . first sc;
    .observer.postprocess[]
    ];
 };

// Post-process performance test results
.observer.postprocess:{
  // Perform post-processing, set to root namespace and optionally return
  .lg.o[`postprocess;"Beginning post-processing..."];
  output:.observer.postprocessinner[.observer.results;.observer.feedhandle(`.feed.looptime);] each .observer.scenarios;
  stats1:raze first each output;
  stats2:raze last each output;
  `transit`mps set' (stats1;stats2);
  system each "rm " ,/: 1_'string .observer[`tphandle`kxhandle] @\: (`.u.L);
  .lg.o[`postprocess;"Post-processing complete..."];
  if[not .observer.savetodisk;.lg.o[`postprocess;"Complete."];:(stats1;stats2)];

  // Save results to disk if applicable
  .lg.o[`postprocess;"Saving results to disk..."];
  if[not `results in key hsym `$.observer.perfdir;system "mkdir ",.observer.perfdir,"/results"];
  (hsym `$.observer.perfdir,"/results/transit_",ssr[string .z.p;"[D.:]";"_"],".csv") 0: csv 0: stats1;
  (hsym `$.observer.perfdir,"/results/mps_",ssr[string .z.p;"[D.:]";"_"],".csv") 0: csv 0: stats2;
  .lg.o[`postprocess;"Complete."];
 };

// Extract statistics from a given scenario
.observer.postprocessinner:{[tab;looptime;scenario]
  // Select out each scenario and take the middle 50%
  tab:select from tab where batching=first scenario,pubmode=last scenario;
  midtab:select from tab where time within (("v"$(0.25;0.75) */: looptime) + exec first time from tab);

  // Get transit time stats and find the 'drift' between the first and last 10% of the results
  vals:"n"$'(med;avg;max) @/:\: value exec feedtotp,tptoconsumer,feedtoconsumer from midtab;
  slices:((::;neg) @\: (floor count[tab]*0.1)) #\: tab;
  drift:"n"$value (-/) ?[;();();cl!med ,/: cl:`feedtotp`tptoconsumer`feedtoconsumer] each slices;

  // Get high-level stats per second with bulk multiplier
  seconds:$[`bulk=last scenario;.observer.bulkrows;1]*select count i by time.second from midtab;   // 1_???
  
  // Conglomerate transit time stats into a keyed table and grab message per second data from table and return
  stats1:`stats xcols update stats:`med`avg`max`drift,batching:first scenario,mode:last scenario from cl !/: vals,enlist drift;
  stats2:select maxmps:max x,medmps:med x,avgmps:avg x,batching:first scenario,mode:last scenario from seconds;
  :(stats1;stats2)
 };

// Set handle from procfile, open handles to feed, consumer, STP and TP
.observer.init:{
  .lg.o[`init;"Setting up process..."];
  .proc.readprocfile .proc.file;
  .servers.startup[];
  .observer.feedhandle:.servers.gethandlebytype[`feed;`any];
  .observer.conshandle:.servers.gethandlebytype[`consumer;`any];
  .observer.stphandle:.servers.gethandlebytype[`segmentedtickerplant;`any];
  .observer.tphandle:.servers.gethandlebytype[`tickerplant;`any];
  .observer.kxhandle:.servers.gethandlebytype[`tick;`any];
  
  // If auto-run is on, begin tests
  if[.observer.autorun;.observer.startrun[]];
 };

// Call init function
.observer.init[];
