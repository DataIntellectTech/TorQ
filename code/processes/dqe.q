\d .dqe

/- default parameters
subscribeto:@[value;`subscribeto;`];                          /-list of tables subscribed to
subscribesyms:@[value;`subscribesyms;`];                      /-list of syms subscribed to
schema:@[value;`schema;0b];                                   /-retrieve schema from tickerplant
tickerplanttypes:@[value;`tickerplanttypes;`tickerplant];     /-list of tickerplant types to try and make a connection to
replaylog:@[value;`replaylog;0b];                             /-replay the tickerplant log file
tpconnsleepintv:@[value;`tpconnsleepintv;10];                 /-default wait time before trying to reconnect to discovery/TP
/- end of default parameters

subscribe:{[]
  if[0=count s:.sub.getsubscriptionhandles[tickerplanttypes;();()!()];:()];
  .lg.o[`subscribe;"found available tickerplant, attempting to subscribe"];
  /-set the date that was returned by the subscription code i.e. the date for the tickerplant log file
  /-and a list of the tables that the process is now subscribing for
  subinfo: .sub.subscribe[subscribeto;subscribesyms;schema;replaylog;first s];
  /-setting subtables and tplogdate globals
  .dqe,:subinfo
  }

init:{
  .servers.CONNECTIONS:distinct .servers.CONNECTIONS, .dqe.tickerplanttypes;
  .lg.o[`init;"searching for servers"];
  .servers.startup[];
  subscribe[];
  }

tableexists:{x in tables[]};                                  /-function to check for table, param is table name as a symbol

\d .

.dqe.init[]
