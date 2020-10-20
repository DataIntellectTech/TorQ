// Server settings
.servers.enabled:1b;
.servers.CONNECTIONS:`tickerplant`segmentedtickerplant;
.servers.USERPASS:`admin:admin;
.servers.HOPENTIMEOUT:30000;

// Feed parameters
.feed.sym:`AMD`AIG`AAPL`DELL`DOW`GOOG`HPQ`INTL`IBM`MSFT;
.feed.mode:" ABHILNORYZ";
.feed.cond:" 89ABCEGJKLNOPRTWZ";
.feed.ex:"NO";
.feed.src:`BARX`GETGO`SUN`DB;
.feed.side:`buy`sell;
.feed.bulkrows:1000;
.feed.looptime:00:01;