// Paths to process CSV, strings to move the sub CSV around
processcsv:getenv[`KDBTESTS],"/stp/wdb/process.csv";
mv1:" " sv enlist["mv"],@[getenv each `KDBTESTS`TORQHOME;0;,;"/rdbsub.csv"];
mv2:" " sv enlist["mv"],@[getenv each `TORQHOME`KDBTESTS;0;,;"/rdbsub.csv"];

// Function projections (using functions from helperfunctions.q)
startproc:startorstopproc["start";;processcsv];