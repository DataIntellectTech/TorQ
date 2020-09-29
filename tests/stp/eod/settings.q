// IPC connection parameters
.servers.CONNECTIONS:`rdb`segmentedtickerplant;
.servers.USERPASS:`admin:admin;

// Paths to process CSV and test STP log directory
processcsv:getenv[`KDBTESTS],"/stp/periodend/process.csv";

// Function projections (using functions from helperfunctions.q)
startproc:startorstopproc["start";;processcsv];
stopproc:startorstopproc["stop";;processcsv];

// Flag to save tests to disk
.k4.savetodisk:1b;