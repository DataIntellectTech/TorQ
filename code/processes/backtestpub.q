\d .backtest

init:{[]
   .servers.CONNECTIONS:inputdbtype,outputdbtype;
   .servers.startup[];
   / Used to get data from source to replay as real time 
   .backtest.hdbh:first exec w from .servers.getservers[`proctype;inputdbtype;()!();0b;0b];
   / Used to send results of the backtest
   .backtest.rdbh:neg first exec w from .servers.getservers[`procname;dbprocname;()!();0b;0b];
 };

datareplay:{[params;id]
   .dbg.replay:(params;id;.z.w);
   params[`h]:hdbh;
   / Return the messages to be replayed
   msgs:.datareplay.tablesToDataStream `name`version _params;
   / Publishing configuration of backtest, needs to run after datareplay to pick up dataconfig
   rdbh(`upd;`config;(id;.z.p;;;;;enlist query;`h _params). params`name`version`sts`ets);
   / Kick off upd/timers on the instance being backtested
   {neg[.z.w](`.backtest.extractmessage;x)}each msgs
 };

\d .

.backtest.init[];
