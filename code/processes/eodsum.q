\d .eodsum

handler:{[port]
  
  h:@[hopen;(hsym `$":" sv ("localhost";string port;"eod";"pass");2000);0];

  if[not h;                                                                                                             /error trap for opening handle
     -2"Cannot create connection to host:localhost, port:",string port;
     -1"";
     exit 1;
   ];

  :h;
 };


tabler:{[h;pt]											     
  /function to query trade and quote data for required calculation 
  /outputs join results as table

  sumt:h({[x;y]select totalVol:sum size,no.ofTrades:count i by sym from x where date=y};`trade;pt);			/query data

  sumq:h({[x;y]select time,sym,bid,ask from x where date=y};`quote;pt);
  
  sumq:select                                                                                            
         avgSpread:avg spread,
         TWAS:dur wavg spread
       by 
         sym 
       from 
         update 
           dur:(exec last time from sumq)^next[time]-time,
           spread:ask-bid 
         by 
           sym 
         from 
           sumq;

  :sumtab:sumt lj sumq;													/join results
 };						
                                                                               			

savedown:{[sumtab;pt]
  /function to save eod data to hdb partiton on disk
  
  fpath:hsym `$raze(.eodsum.hh(system;"pwd")),"/",string[pt],"/eodsum/";
  
  fpath set .Q.en[fpath;0!sumtab];
 };

init:{

  hh::handler[1403];
  hw::handler[1405];
  .lg.o[`eodsum;"handles to hdb and wdb opened"]
 };

sdwrap:{[pt]
  /wrapper function for eod summary table  

  sumtab:tabler[hh;pt];
  .lg.o[`eodsum;"summary table generated successfully"]   
  savedown[sumtab;pt];
  .lg.o[`eodsum;"summary table saved down successfully"]
 };

init[]
