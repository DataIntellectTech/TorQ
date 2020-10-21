// REDO DIS

// function to get all the above stats together:
// takes in [timingtp or timingstp or timingdatatp or timingdatastp; name choice of timing csv; name choice of msg count csv]
.obs.getstats:{[tab;name1;name2]
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

// Observer init function
.observer.init:{
  .servers.startup[];
  .observer.feedhandle:.servers.gethandlebytype[`feed;`any];
  .observer.conshandle:.servers.gethandlebytype[`consumer;`any];
  };