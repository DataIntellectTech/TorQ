/-function to generate data to be saved to disk and merged by wdb - 3 different currency pairs for given specified counts so can test for values less than, equal to and greater than merge limit
data:{
  numaususd:25000;
  numeurusd:30000;
  numusdchf:45000;
  numrows:numaususd+numeurusd+numusdchf;
  starttime:09:00:00.000;
  endtime:17:00:00.000;
  time:.z.D+`#asc starttime+numrows?endtime-starttime;
  sym:0N?((numaususd#`AUDUSD),numeurusd#`EURUSD),numusdchf#`USDCHF;
  price:10+numrows?100;
  size:1000*price;
  ex:numrows?`o`n;
  `xdaily set ([]time;sym;bidprice:0.9*price;bidsize:0.9*size;askprice:1.1*price;asksize:1.1*size;ex);
 }
/- generate mock data for in memory table in wdb to be saved to disk
data[];
