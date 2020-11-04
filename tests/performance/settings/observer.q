// Server settings
.servers.CONNECTIONS:`tickerplant`segmentedtickerplant`feed`consumer;
.servers.USERPASS:`admin:admin;

// List of all TP types to go through
.observer.tplist:`defaultbatch`memorybatch; //`immediate`vanillaimm`vanillabatch;
.observer.scenarios:.observer.tplist cross `single`bulk;

// System line to reset TP, performance directory
.observer.tpreset:"l ",getenv[`KDBCODE],"/processes/tickerplant.q";
.observer.perfdir:getenv[`KDBTESTS],"/performance";

// Run tests on startup or not
.observer.autorun:1b;

// Size of bulk updates
.observer.bulkrows:1000;

// Write results to disk
.observer.savetodisk:0b;
