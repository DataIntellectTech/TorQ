\d .backtest

/ Used for data replay
inputdbtype:`hdb;
/Used to capture results
dbprocname:`backtestdb;
outputdbtype:`backtestdb;
/Used to publish data from replay to engine and results
pubprocname:`backtestpub;
pubproctype:`backtest;
/ Used by engine getting backtested
proctypes:outputdbtype,pubproctype;

\d .
