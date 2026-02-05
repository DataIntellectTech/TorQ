\d .backtest

init:{[]
   .servers.CONNECTIONS:`hdb`backtestdb;
   .servers.startup[];
   .backtest.hdb:first exec w from .servers.SERVERS where proctype=`hdb;
   .backtest.rdb:neg first exec w from .servers.SERVERS where procname=`backtestdb;
 };

datareplay:{[params;id]
   .dbg.replay:(params;id;.z.w);
   params[`h]:first exec w from .servers.SERVERS where proctype=`hdb;
   msgs:.datareplay.tablesToDataStream `name`version _params;
   / Publishing configuration of backtest, needs to run after datareplay to pick up dataconfig
   rdb(`upd;`config;(id;.z.p;;;;;enlist query;`h _params). params`name`version`sts`ets);
   {neg[.z.w](`.backtest.extractmessage;x)}each msgs
 };

\d .

.backtest.init[];
