// Paths to process CSV, strings to move the sub CSV around
processcsv:getenv[`KDBTESTS],"/stp/wdb/process.csv";
mv1:" " sv enlist["mv"],@[getenv each `KDBAPPCONFIG`TORQHOME;0;,;"/rdbsub.csv"];
mv2:" " sv enlist["mv"],@[getenv each `TORQHOME`KDBAPPCONFIG;0;,;"/rdbsub.csv"];

// Function projections (using functions from helperfunctions.q)
startproc:startorstopproc["start";;processcsv];