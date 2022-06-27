tradedata:{[numrows]
  time:numrows#.z.p;
  sym:numrows?`AUDUSD`EURUSD`USDCHF;
  price:10+numrows?100.0;
  size:`int$1000*price;
  stop:numrows?0b;
  cond:numrows?"ABK";
  ex:numrows?"NO";
  side:numrows?`buy`sell;
  `xdailyt set ([]time;`g#sym;price;size;stop;cond;ex;side);
 };

quotedata:{[numrows]
  time:numrows#.z.p;
  sym:numrows?`AUDUSD`EURUSD`USDCHF;
  bid:10+numrows?100.0;
  ask:bid*1.1;
  bsize:`long$100*bid;
  asize:`long$10*bsize;
  mode:numrows?" YRL";
  ex:numrows?"NO";
  src:numrows?`GETGO`DB`SUN;
  `xdailyq set ([]time;`g#sym;bid;ask;asize;bsize;mode;ex;src);
 };

/- generate mock data for in memory tables in wdb to be saved to disk
gendata:{[numquotes;numtrades]
 tradedata[numtrades];
 quotedata[numquotes];
 };

gendata[100000;50000];
