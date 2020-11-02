// Settings file for consumer process

// Server settings
.servers.enabled:1b;
.servers.CONNECTIONS:`tickerplant`segmentedtickerplant`feed;
.servers.USERPASS:`admin:admin;

// Process settings
.consumer.singlecols:`time`sym`feedtime;
.consumer.bulkcols:`time`sym`price`size`src`ex`cond`mode`side`feedtime;

// Results table schema
.consumer.results:flip `time`feedtime`consumertime`feedtotp`tptoconsumer`feedtoconsumer`batching`pubmode!"PPPNNNSS" $\: ();