// IPC connection parameters
.servers.CONNECTIONS:`rdb`segmentedtickerplant`patcher;
.servers.USERPASS:`admin:admin;

hostA:`localhost;  // IP address/hostname for primary host
hostB:`localhost;  // IP address/hostname for secondary host

testversiontable: hsym `$getenv[`KDBAPPCONFIG],"/testfunctionversion"

// Paths to process CSV and test STP log directory
processcsv:getenv[`KDBTESTS],"/patcher/process.csv";

// Function projections (using functions from helperfunctions.q)
startproc:startorstopproc["start";;processcsv];
stopproc:startorstopproc["stop";;processcsv];
