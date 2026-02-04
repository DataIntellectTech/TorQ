\d .backtest

/TESTING:TO BE REMOVED
test:`name`version`tabs`sts`ets`interval`timer`timerfunc!(`vwappublisher;1;`trade;2026.01.22D00:00:00.00;2026.01.22D01:00:00.00;0D00:10:00.00;1b;`.vwapsub.logvwap);

initRan:0b;

init:{[]
   requiredProc:`backtestdb;
   .servers.registerfromdiscovery[requiredProc;1b];
   .backtest.rdb:neg first exec w from .servers.SERVERS where procname=requiredProc;
   `upd set .backtest.upd;
   .backtest.id:first 1?0Ng;
   .backtest.initRan:1b;
 };

upd:{[t;d]
   /Running old upd function
   .[` sv `,.proc.proctype,`upd;(t;d)];
 };  

/ To run backtest, optional where
run:{[params]
   if[not initRan;'"Please run .backtest.init to override functions to backtest before running .backtest.run";];
   if[not all `name`version`tabs`sts`ets`interval`timer`timerfunc in key params;'"Please ensure all mandatory params have been populated";];
   / Remove optional where when not required
   if[`where in key params; if[not count params`where;params:`where _params]];
   params[`h]:first exec w from .servers.SERVERS where proctype=`hdb;
   msgs:.datareplay.tablesToDataStream `name`version _params;
   / Publishing configuration of backtest
   rdb(`upd;`config;(id;.z.p;;;;;enlist query;params). params`name`version`sts`ets);
   value each msgs`msg;
 };

\d .
