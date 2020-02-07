\d .dqc
xmarketalert:{[tab]                                     // alerts user when bid has exceeded the ask in market data
  data:select from tab where bid>ask;
  $[0=count data;
    (1b;"bid has not exceeded the ask in market data");
    (0b;"bid has exceeded the ask ",string[count data]," times and they have occured at: ","," sv string exec time from data)]
  }
