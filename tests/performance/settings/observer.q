// Server settings
.servers.CONNECTIONS:`tickerplant`segmentedtickerplant`feed`consumer;
.servers.USERPASS:`admin:admin;

// List of all TP types to go through
.observer.tplist:`defaultbatch`memorybatch`immediate`vanilla;
.observer.scenarios:.observer.tplist cross `single`bulk;

// Run tests on startup or not
.observer.autorun:1b;

// Size of bulk updates
.observer.bulkrows:1000;