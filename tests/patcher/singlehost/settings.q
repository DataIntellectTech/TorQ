// IPC connection parameters
.servers.CONNECTIONS:`rdb`segmentedtickerplant`patcher;
.servers.USERPASS:`admin:admin;

testversiontable: hsym `$getenv[`KDBAPPCONFIG],"/testfunctionversion"

// Paths to process CSV and test STP log directory
processcsv:getenv[`KDBTESTS],"/patcher/singlehost/process.csv";

// Function projections (using functions from helperfunctions.q)
startproc:startorstopproc["start";;processcsv];
stopproc:startorstopproc["stop";;processcsv];
