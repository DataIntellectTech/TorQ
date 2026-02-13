\d .backtest

/ Params to be passed to .backtest.run to kick off backtest, edit to fit usecase
requiredparams:`name`version`tabs`sts`ets`replayinterval`timer`timerinterval`timerfunc!(`;1;`;0Np;0Np;0Nn;0b;0Nn;`);
initRan:0b;

init:{[]
   system"l ",getenv[`KDBCONFIG],"/settings/backtest.q";
   .servers.registerfromdiscovery[proctypes;1b];
   / Close open subscriptions to tickerplant
   .servers.removerows exec i from .servers.SERVERS where w in exec w from .sub.SUBSCRIPTIONS;
   .backtest.rdbh:neg first exec w from .servers.getservers[`procname;dbprocname;()!();0b;0b];
   .backtest.pubh:neg first exec w from .servers.getservers[`procname;pubprocname;()!();0b;0b];
   `.u.pub set .backtest.pub;
   .backtest.initRan:1b;
 };

/ Receive full message from datareplay, extract details from msg before running msg func
extractmessage:{[msgs]
   msg:msgs`msg;
   .backtest.simtime:msgs`time;
   .backtest.name:first msg;
   value msg
 };

pub:{[t;d]
   rdbh(`upd;`output;(.z.p;id;simtime;name;d));
 };

/ To run backtest, optional where
run:{[params]
   params:validateparams[params];
   / Random guid generated to match config to output
   .backtest.id:first -1?0Ng;
   / Kick off backtest from backtestpub which will replay the data back through the process running backtest
   pubh(`.backtest.datareplay;params;.backtest.id); 
 };

/ Cannot run .backtest.run params until params is in correct format with helpful instruction on how to fix
validateparams:{[params]
   if[.proc.procname like "*backtest*";
      '"Backtest should be ran from the process you are backtesting not backtest instance itself";
      ];
   if[not initRan;
      '"Please run .backtest.init to override functions to backtest before running .backtest.run";
      ];
   / Check param datatypes
   if[any wrongtyp:not {(type x y)=type .backtest.requiredparams y}[params;]each kp:key[params]except `where;
      '"The following param key(s) is not of the correct datatype - ","," sv string kp where wrongtyp;
      ];
   / Check params keys complete
   if[any missingparams:not (requiredkeys:key requiredparams) in key params;
      '"Not all mandatory params have been used - ", "," sv string requiredkeys where missingparams;
      ];
   / Check params keys non null on complusary keys, (replay interval optional but timer interval must be populated when timer 1b)
   if[count missingparams:where null checkparams:(`replayinterval,$[params`timer;();`timerinterval`timerfunc]) _params;
      '"Not all mandatory params have been populated - ", "," sv string missingparams;
      ];
   / Remove optional where, when not used
   if[`where in key params; 
      if[not count params`where;params:`where _params]
      ];
   params
 };


\d .
