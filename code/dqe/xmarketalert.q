\d .dqe 
xmarketalert:{[tab]                                     // alerts user when bid has exceeded the ask in market data
  data:select from tab where bid>ask;
  $[0=count data;
    (1b;"bid has not exceeded the ask in market data");
    (0b;raze ("bid has exceeded the ask ";(string count data);" times and they have occured at: ";($[1=count exec time from data;string exec time from data;"," sv string exec time from data])))]
  }
