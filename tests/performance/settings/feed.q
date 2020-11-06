// Server settings
.servers.enabled:1b;
.servers.CONNECTIONS:`tickerplant`segmentedtickerplant`observer`tick;
.servers.USERPASS:`admin:admin;
.servers.HOPENTIMEOUT:30000;

// Feed parameters
.feed.sym:`AMD`AIG`AAPL`DELL`DOW`GOOG`HPQ`INTL`IBM`MSFT;
.feed.mode:" ABHILNORYZ";
.feed.cond:" 89ABCEGJKLNOPRTWZ";
.feed.ex:10b;
.feed.src:`BARX`GETGO`SUN`DB;
.feed.side:`buy`sell;
.feed.maxprice:100.0;
.feed.maxsize:50;
.feed.looptime:00:01:00;

// Create bulk update
.feed.bulk:.feed.bulkrows ?' .feed[`sym`maxprice`maxsize`src`ex`cond`mode`side];