// Settings file for consumer process

// Server settings
.servers.enabled:1b;
.servers.CONNECTIONS:`tickerplant`segmentedtickerplant`feed`tick;
.servers.USERPASS:`admin:admin;

// Process settings
.consumer.singlecols:`time`batch`mode`feedtime;
.consumer.bulkcols:`time`sym`price`size`src`ex`cond`mode1`side`batch`mode`feedtime;
.consumer.whereclause:((=;`mode;enlist `single);(=;`mode;enlist `bulk));

// Results table schema
.consumer.results:flip `batching`pubmode`time`feedtime`consumertime`feedtotp`tptoconsumer`feedtoconsumer!"SSPPPNNN" $\: ();