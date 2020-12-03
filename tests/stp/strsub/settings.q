// IPC connection parameters
.servers.CONNECTIONS:`segmentedtickerplant;
.servers.USERPASS:`admin:admin;

// Paths to process CSV, strings to move the sub CSV around
processcsv:getenv[`KDBTESTS],"/stp/exit/process.csv";
tstlogs:"tstlogs";
tstlogsdir:hsym `$getenv[`KDBTPLOG],"/",tstlogs,"_",string .z.d;

// Function projections (using functions from helperfunctions.q)
startproc:startorstopproc["start";;processcsv];

// Subscription strings to test
simplesyms:"AMZN,MSFT";
complexwhr:"sym in `GOOG`IBM,price>90";
columnlist:"sym,price";
badwhr:"sm in `GOOG`IBM,price>90";