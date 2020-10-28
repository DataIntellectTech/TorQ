params:([proctype:`dailyhdb`monthlyhdb`yearlyhdb`dailyrdb`monthlyrdb`yearlyrdb]
  func:`generatehdb`generatehdb`generatehdb`generaterdb`generaterdb`generaterdb;
  partitiontype:`date`month`year`date`month`year;
  hdbname:`dailyhdb`monthlyhdb`yearlyhdb```;
  n:5 5 5 6 6 6;
  tablename:`xdaily`xmonthly`xyearly`xdaily`xmonthly`xyearly;
  nrecord:10 10 10 10 10 10
 );

generatehdb:{[x]
  x:updatehdbdir x;
  setondisk[x].'exec .getrange[partitiontype]'[til n]from x;
  loadhdb x`hdbdir;
 };

updatehdbdir:{[x]update hdbdir:` sv(testfolder;`hdb;hdbname)from x};
loadhdb:{[hdbdir]system "l ",1_string hdbdir};

generaterdb:{[x]setinmemory[x]. exec .getrange[partitiontype][n]from x};

.getrange.date:{[n]0D+2000.01.01+0 1+n};
.getrange.month:{[n]0D+.Q.addmonths[2000.01.01;0 1+n]};
.getrange.year:{[n]0D+.Q.addmonths[2000.01.01;12*0 1+n]};

generatedata:{[x;start;end]
  end:end-1;
  difference:(end-start)%-1+x`nrecord;
  timestamp:start+til[x`nrecord]*difference;
  syms:`AUDUSD`EURUSD`USDCHF;
  sym:`p#syms where 3#x`nrecord;
  source:(`$"source",/:string til nsyms:count syms)where 3#x`nrecord;
  id:"x",/:string til count source;
  offset:til[nsyms]*difference%2*nsyms;
  time:raze timestamp+/:offset;
  sourcetime:raze timestamp+/:2*offset;
  price:raze 100+x[`nrecord]?/:10*1+til nsyms;
  size:raze 1000+x[`nrecord]?/:100*1+til nsyms;
  :([]sym;source;id;`timestamp$time;`timestamp$sourcetime;bidprice:0.9*price;bidsize:0.9*size;askprice:1.1*price;asksize:1.1*size);
 };

setondisk:{[x;start;end]
  data:generatedata[x;start;end];
  x:update target:.Q.par[hdbdir;partitiontype$first start;tablename]from x;
  exec .Q.dd[target;`]set .Q.en[hdbdir;data]from x;
  :x;
 };

setinmemory:{[x;start;end]
  x[`tablename]set generatedata[x;start;end];
 };

run:{[]
  x:params .proc.proctype;
  :x[`func]x;
 };

run[];
