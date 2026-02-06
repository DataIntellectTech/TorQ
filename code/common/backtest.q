\d .backtest

/ Params to be passed to .backtest.run to kick off backtest, edit to fit usecase
test:`name`version`tabs`sts`ets`datainterval`timer`timerinterval`timerfunc!(`;1;`;0Np;0Np;0Nn;0b;0Nn;`);
initRan:0b;

/ TO BE DELETED, TESTING ONLY
test:`name`version`tabs`sts`ets`datainterval`timer`timerinterval`timerfunc!(`vwappublisher;1;`trade;2026.01.22D00:00:00.00;2026.01.22D01:00:00.00;0Nn;1b;0D00:10:00.00;`.vwapsub.logvwap);

init:{[]
   requiredProcs:`backtestdb`backtestpub;
   .servers.registerfromdiscovery[requiredProcs;1b];
   .backtest.rdbh:neg first exec w from .servers.SERVERS where procname=`backtestdb;
   .backtest.pubh:neg first exec w from .servers.SERVERS where procname=`backtestpub;
   `.u.pub set .backtest.pub;
   .backtest.initRan:1b;
 };

/ Receive full message from datareplay, extract details from msg before running msg func
extractmessage:{[msgs]
   .dbg.msg:msgs;
   msg:msgs`msg;
   .backtest.simtime:msgs`time;
   .backtest.name:first msg;
   value msg
 };

pub:{[t;d]
   .dbg.pub:(t;d);
   rdbh(`upd;`output;(.z.p;id;simtime;name;d));
 };

/ To run backtest, optional where
run:{[params]
   params:validaterun[params];
   / Random guid generated to match config to output
   .backtest.id:first -1?0Ng;
   / Kick off backtest from backtestpub which will replay the data back through the process running backtest
   pubh(`.backtest.datareplay;params;.backtest.id); 
 };

validaterun:{[params]
   if[.proc.procname=`backtestpub;'"Backtest should be ran from the process you are backtesting not backtest instance itself"];
   if[not initRan;'"Please run .backtest.init to override functions to backtest before running .backtest.run";];
   if[not all (key[test]except `where) in key params;'"Please ensure all mandatory params have been populated";];
   if[count where null `datainterval _params;'"Not all mandatory keys have been populated"];
   / Remove optional where, when not required
   if[`where in key params; if[not count params`where;params:`where _params]];
   params
 };

\d .
