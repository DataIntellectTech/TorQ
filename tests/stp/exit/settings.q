// IPC connection parameters
.servers.CONNECTIONS:`rdb`segmentedtickerplant;
.servers.USERPASS:`admin:admin;

// Paths to process CSV, strings to move the sub CSV around
processcsv:getenv[`KDBTESTS],"/stp/exit/process.csv";
tstlogs:"stpex";
tstlogsdir:hsym `$getenv[`KDBTPLOG],"/",tstlogs,"_",string .z.d;

// Function projections (using functions from helperfunctions.q)
startproc:startorstopproc["start";;processcsv];