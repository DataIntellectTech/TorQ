\d .eodsum

tabler:{											     
  /function to connect to HDB, query trade and quote data for required calculation 
  /outputsjoin results as table
  
  h:@[hopen;(`::9803:admin:admin;2000);0];                                                              		/open handle to hdb

  if[not h;                                                                                     			/error trap for opening handle
     -2"Cannot create connection to HDB on host:localhost, port:9803"];
     -1"";
     exit 1;
   ];

  sumt:h({select totalVol:sum size,no.ofTrades:count i by sym from x where date=.z.d-1};`trade);/query data

  sumq:h({select time,sym,bid,ask from x where date=.z.d-1};`quote);
  
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
                                                                               			

savedown:{[sumtab]
  /function to save eod data to hdb partiton on disk
  
  fpath:hsym `$string[.wdb.hdbdir],"/",string[.z.d-1],"/eodsum/";
  
  fpath set .Q.en[fpath;0!sumtab];
 };

init:{
  /initialisation function for eod summary table  

  sumtab:tabler[];
  
  savedown[sumtab];
 };

