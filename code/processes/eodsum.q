\d .eodsum

connected:{[]
  /function to check if hdb and wdb handles are open
  :2=count .z.W;
 };

connsleepintv:10;													/sleep time for connection attempts

handler:{[port]
  /function to open a handle to supplied port 
  h:@[hopen;(hsym `$":" sv ("localhost";string port;"eod";"pass");2000);0];

  if[not h;                                                                                                             /error trap for opening handle
     -2"Cannot create connection to host:localhost, port:",string port;
     -1"";
   ];

  :h;
 };

queryt:{[h;pt]
  /function to query trade table 
   :sumt:h({[x;y]select totalVol:sum size,noOfTrades:count i by sym from x where date=y};`trade;pt);
 };

queryq:{[h;pt]
  /function to query quote table
  sumq:h({[x;y]select time,sym,bid,ask from x where date=y};`quote;pt);
  
  :sumq:select avgSpread:avg spread,TWAS:dur wavg spread by sym from
        update dur:(exec last time from sumq)^next[time]-time,spread:ask-bid by sym from sumq;
 };

tabler:{[h;pt]											     
  /function to build summary table from trade/quote queries
  /outputs join results as table
  sumt:queryt[h;pt];			
 
  sumq:queryq[h;pt];

  :sumtab:sumt lj sumq;													/join results
 };						
                                                                               			

savedown:{[sumtab;h;pt]
  /function to save eod data to hdb partiton on disk
  fpath:hsym `$"/" sv (raze(.eodsum.hh(system;"pwd"));string[2018.03.05];"eodsum";"");
  
  fpath set .Q.en[fpath;0!sumtab];
 };

init:{
  /initialisation function to open required handles
  hh::handler[1403];
  hw::handler[1405];
  .lg.o[`eodsum;"handles to hdb and wdb opened"]
 };

sdwrap:{[pt]
  /wrapper function for eod summary table  
  while[hh({not string[x] in system "ls"};pt);(::)];									/wait for partition to be saved to disk
  sumtab:tabler[hh;pt];													/build summary table
  .lg.o[`eodsum;"summary table generated successfully"];   
  savedown[sumtab;hh;pt];												/save down summary table
  .lg.o[`eodsum;"summary table saved down successfully"];	
 };	

while[not connected[];													/attempt initialisation, connect to hdb/wdb every x seconds until successful
  .os.sleep[connsleepintv];
  init[];
 ];														
