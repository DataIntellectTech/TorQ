// Server settings
.servers.CONNECTIONS:`tickerplant`segmentedtickerplant`feed`consumer`tick;
.servers.USERPASS:`admin:admin;

// List of all TP types to go through
.observer.tplist:`defaultbatch`memorybatch`immediate`vanillaimm`vanillabatch`tickimm`tickbatch;
// .observer.tplist:`vanillaimm`vanillabatch`tickimm`tickbatch;
.observer.scenarios:.observer.tplist cross `single`bulk;

// System line to reset TP, performance directory
.observer.tpreset:"l ",getenv[`KDBCODE],"/processes/tickerplant.q";
.observer.tickreset:"l ",getenv[`KDBTESTS],"/performance/code/tick.q";
.observer.perfdir:getenv[`KDBTESTS],"/performance";

// Run tests on startup or not
.observer.autorun:1b;

// Size of bulk updates
.observer.bulkrows:100;

// Write results to disk
.observer.savetodisk:1b;
