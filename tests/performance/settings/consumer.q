// Settings file for consumer process

// Server settings
.servers.enabled:1b;
.servers.CONNECTIONS:`tickerplant`segmentedtickerplant;
.servers.USERPASS:`admin:admin;

// Process settings
.consumer.tickerplanttypes:`tickerplant`segmentedtickerplant;
.consumer.gatewatypes:`none;
.consumer.replaylog:0b;
.consumer.tpmode:`timingstpautobatch;
.consumer.updmode:`singlestp;

// Results table schema
.consumer.results:`time`feedtime`consumertime`feedtotp`tptoconsumer`feedtoconsumer!"PPPNNN" $\: ();