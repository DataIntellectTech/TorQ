/ generate data for rdb demo

sn:2 cut (
 `AMD;"ADVANCED MICRO DEVICES";
 `AIG;"AMERICAN INTL GROUP INC";
 `AAPL;"APPLE INC COM STK";
 `DELL;"DELL INC";
 `DOW;"DOW CHEMICAL CO";
 `GOOG;"GOOGLE INC CLASS A";
 `HPQ;"HEWLETT-PACKARD CO";
 `INTC;"INTEL CORP";
 `IBM;"INTL BUSINESS MACHINES CORP";
 `MSFT;"MICROSOFT CORP")

s:first each sn
n:last each sn
p:33 27 84 12 20 72 36 51 42 29 / price
m:" ABHILNORYZ" / mode
c:" 89ABCEGJKLNOPRTWZ" / cond
e:"NONNONONNN" / ex
src:`BARX`GETGO`SUN`DB
side:`buy`sell

/ init.q

cnt:count s
pi:acos -1
gen:{exp 0.001 * normalrand x}
normalrand:{(cos 2 * pi * x ? 1f) * sqrt neg 2 * log x ? 1f}
randomize:{value "\\S ",string "i"$0.8*.z.p%1000000000}
rnd:{0.01*floor 0.5+x*100}
vol:{10+`int$x?90}

/ randomize[]
\S 235721

/ =========================================================
/ generate a batch of prices
/ qx index, qb/qa margins, qp price, qn position
batch:{
 d:gen x;
 qx::x?cnt;
 qb::rnd x?1.0;
 qa::rnd x?1.0;
 n:where each qx=/:til cnt;
 s:p*prds each d n;
 qp::x#0.0;
 (qp raze n):rnd raze s;
 p::last each s;
 qn::0}
/ gen feed for ticker plant

len:1000
batch len

maxn:1000 / max trades per tick

/ function t to generate dummy trade data
t:{
 if[not (qn+x)<count qx;batch len];
 i:qx n:qn+til x;qn+:x;
 (s i;qp n;`int$x?99;1=x?20;x?c;e i;x?side)
 };

/- use the discovery service to find the tickerplant to publish data to

.servers.startup[]
h:.servers.gethandlebytype[`segmentedtickerplant`tickerplant;`any]

// appends timestamp when feed is called and when consumer upd is called
// use: feedtimetp each til 1000000
feedsingletp:{
  curtime:.z.p;
  (neg h)(`.u.upd;`timing0;(`a;curtime));(neg h)(::)
 };

feedsinglestp:{
  curtime:.z.p;
  (neg h)(`.u.upd;`timing1;(`a;curtime));(neg h)(::)
 };

// appends timestamp when feed is called and when consumer upd is called
// fills with dummy trade data to test sending through 100k message one at a time
// use: feeddatatp each til 10
feedbulktp:{
  curtime:.z.p;
  (neg h)(`.u.upd;`timingdata0;flip (flip t[maxn]),'curtime);(neg h)(::)
 };

feedbulkstp:{
  curtime:.z.p;
  (neg h)(`.u.upd;`timingdata1;flip (flip t[maxn]),'curtime);(neg h)(::)
 };

// expand to full data
// firing messages through repeatedly
// sending thorugh 100k one at a time
// stp wtih error mode