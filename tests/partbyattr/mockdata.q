data:{[numrows;table]
  starttime:09:00:00.000;
  endtime:17:00:00.000;
  time:.z.D+`#asc starttime+numrows?endtime-starttime;
  sym:numrows?`AUDUSD`EURUSD`USDCHF;
  price:10+numrows?100;
  size:1000*price;
  ex:numrows?`o`n;
  table set ([]time;sym;bidprice:0.9*price;bidsize:0.9*size;askprice:1.1*price;asksize:1.1*size;ex);
 };
/- generate mock data for in memory tables in wdb to be saved to disk
data'[(100000;50000);`xdaily1`xdaily2];
