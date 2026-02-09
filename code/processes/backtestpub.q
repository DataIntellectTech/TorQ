\d .backtest

init:{[]
   .servers.CONNECTIONS:`hdb,outputdbtype;
   .servers.startup[];
   / Used to get data from source to replay as real time 
   .backtest.hdb:first exec w from .servers.SERVERS where proctype=`hdb;
   / Used to send results of the backtest
   .backtest.rdb:neg first exec w from .servers.SERVERS where procname=`backtestdb;
 };

datareplay:{[params;id]
   .dbg.replay:(params;id;.z.w);
   params[`h]:hdb;
   / Return the messages to be replayed
   msgs:.datareplay.tablesToDataStream `name`version _params;
   / Publishing configuration of backtest, needs to run after datareplay to pick up dataconfig
   rdb(`upd;`config;(id;.z.p;;;;;enlist query;`h _params). params`name`version`sts`ets);
   / Kick off upd/timers on the instance being backtested
   {neg[.z.w](`.backtest.extractmessage;x)}each msgs
 };

\d .

.backtest.init[];
