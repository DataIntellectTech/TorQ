//Number of queries on a given process by hour (or any given bucket)
testfunc:{.gw.syncexec[({[x;y]select query_suc:count i by procname from usage where time within (x;y)};x;y);`queryrdb]}
//Number of queries ran by a specific user
//Number of distinct users querying a process
//Return list of queries that run over a given run time
//Return the date range queried on a process


/Number of queries on a given process by hour (or any given bucket)
//d:(`proc`bucket`sd`ed)!(`rdb1;60:.z.d-3;.z.d)
ProcSucErr:{[d]
   .gw.syncexec[({[d]
      $[.proc.proctype=`queryhdb;
         select queries_suc:count where status=first string `c,queries_err:count where status=first string `e
         by time.date,d[`bucket] xbar time.minute from usage
         where date within (d[`sd];d[`ed]),procname=d[`proc];
         select queries_suc:count where status=first string `c,queries_err:count where status=first string `e
         by time.date,d[`bucket] xbar time.minute from usage
         where procname=d[`proc]]};d);`queryhdb`queryrdb];
 };
//ProcSucErrFF:{[`proc;`bucket;sd;ed]
//   .gw.syncexec[({[`proc;`bucket;sd;ed]
//      $[.proc.proctype=`queryhdb;
//
//         ?[`usage;((within;`date;(enlist;`sd;`ed));(=;`procname;`proc));
//         `date`minute!(`time.date;(k){x*y div x:$[16h=abs[@x];"j"$x;x]};`bucket;`time.minute);
//         `queries_suc`queries_err!((#:;(&:;(=;`status;(*:;($:;enlist(`c))))));(#:;(&:;(=;`status;(*:;($:;enlist(`e)))))))];
//
//         ?[`usage;enlist((=;`procname;`proc));
//         `date`minute!(`time.date;(k){x*y div x:$[16h=abs[@x];"j"$x;x]};`bucket;`time.minute);
//         `queries_suc`queries_err!((#:;(&:;(=;`status;(*:;($:;enlist(`c))))));(#:;(&:;(=;`status;(*:;($:;enlist(`e)))))))]]};`proc;`bucket;sd;ed);`queryhdb`queryrdb];
// };
//Number of queries ran by a specific user
//d:(`user`sd`ed)!(`acreehay;.z.d-3;.z.d)
QueryByUser:{[d]
   .gw.syncexec[({[d]
      $[.proc.proctype=`queryhdb;
         select queries_suc:count where status=first string `c,queries_err:count where status=first string `e
         by time.date,procname from usage
         where date within (d[`sd];d[`ed]),user=d[`user];
         select queries_suc:count where status=first string `c,queries_err:count where status=first string `e
         by time.date,procname from usage
         where user=d[`user]]};d);`queryhdb`queryrdb];
 };

//QuerByUser function in functional form 
//Same arguments as above just not in dictionary form
QueryByUserFF:{[username;sd;ed]
   .gw.syncexec[({[username;sd;ed]
      $[.proc.proctype=`queryhdb;
         ?[`usage;((within;`date;(enlist;`sd;`ed));(=;`user;`username));`date`procname!`time.date`procname;`queries_suc`queries_err!((#:;(&:;(=;`status;(*:;($:;enlist(`c))))));(#:;(&:;(=;`status;(*:;($:;enlist(`e)))))))];
         ?[`usage;enlist((=;`user;`username));`date`procname!`time.date`procname;`queries_suc`queries_err!((#:;(&:;(=;`status;(*:;($:;enlist(`c))))));(#:;(&:;(=;`status;(*:;($:;enlist(`e)))))))]]};username;sd;ed);`queryhdb`queryrdb];
 };


//Number of distinct users querying a process
//d:(`proc`bucket`sd`ed)!(`rdb1;60;.z.d-3;.z.d)
DistinctUsers:{[d]
   .gw.syncexec[({[d]
      $[.proc.proctype=`queryhdb;
         select unique_users:count distinct user, users:distinct user
         by time.date,d[`bucket] xbar time.minute from usage
         where date within (d[`sd];d[`ed]),procname=d[`proc];
         select unique_users:count distinct user, users:distinct user
         by time.date,d[`bucket] xbar time.minute from usage
         where procname=d[`proc]]};d);`queryhdb`queryrdb];
 };
//Return list of queries that run over a given run time
//10000;.z.d-3;.z.d
RuntimeLimit:{[lim;sd;ed]
   .gw.syncexec[({[lim;sd;ed]
      $[.proc.proctype=`queryhdb;
         select from usage
         where date within (sd;ed),runtime>lim;
         select from usage
         where runtime>lim]};lim;sd;ed);`queryhdb`queryrdb];
 };

//RuntimeLimit function in functional form
RuntimeLimitFF:{[lim;sd;ed]
   .gw.syncexec[({[lim;sd;ed]
      $[.proc.proctype=`queryhdb;
         ?[`usage;((within;`date;(enlist;`sd;`ed));(>;`runtime;`lim));0b;()];
         ?[`usage;enlist((>;`runtime;`lim));0b;()]]};lim;sd;ed);`queryhdb`queryrdb];
 };

GetDateRange:{[query]
    wherephrase:raze raze (parse query) 2;
    dateindex:1 + wherephrase?`date;
    // index into wherephrase to retrieve date
    date:wherephrase dateindex;

    // if date is a range, drop the 'enlist' element
    if[3=count date; date:1_date];

    :eval each date;
    };

GetClients:{
    clients:first value flip select distinct u from .clients.clients where not u in .usage.ignoreclients;
    if[1=count clients; :first clients];
    :clients;
    };

ParseCmd:{[res]
    cmd:raze value flip select cmd from res;
    remainder:update runtime:.proc.cd[] + runtime from (cols[res] except `cmd)#res;
    reslist:select cmd from update cmd:";" vs ' cmd from res;

    // grab function, query and process and parse out any
    // brackets or slashes in strings
    f:`$1_'first each first value flip reslist;
    q:1_'-1_'first each next each first value flip reslist;
    p:`$-1_'first each next each next each first value flip reslist;

    :remainder,' ([] func:f; query:q; proc:p);
    };

QueryCountsRealtime:{
    clients:GetClients[];
    query:"select count i from usage where u in ", (.Q.s1 clients);
    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryrdb;
    res:handle query;
    :res;
    };

QueryUserCountsRealtime:{
    clients:GetClients[];
    query:"select queries:count i by u from usage where u in ", (.Q.s1 clients);
    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryrdb;
    res:handle query;
    :res;
    };

QueryCountsHistorical:{[date]
    clients:GetClients[];

    $[.z.d<=date; query:(); // log error
        1=count date; query:"select queries:count i from usage where date=", (.Q.s1 date), ", u in ", (.Q.s1 clients);
        2=count date; query:"select queries:count i from usage where date within (", (.Q.s1 first date), "; ", (.Q.s1 last date), "), u in ", (.Q.s1 clients);
        // log error
        query:()]

    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryhdb;
    res:handle raze query;

    :res;
    };

QueryUserCountsHistorical:{[date]
    clients:GetClients;

    $[.z.d<=date; query:(); // log error
        1=count date; query:"select queries:count i by u from usage where date=", (.Q.s1 date), ", u in ", (.Q.s1 clients);
        2=count date; query:"select queries:count i by u from usage where date within (", (.Q.s1 first date), "; ", (.Q.s1 last date), "), u in ", (.Q.s1 clients);
        // log error
        query:()]

    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryhdb;
    res:handle raze query;

    :res;
    };

PeakUsage:{
    clients:GetClients[];
    query:"`time xcol 0!select queries:count i by 10 xbar time.minute, u from usage where u in ", (.Q.s1 clients);
    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryrdb;
    res::handle query; 
    
    time::select distinct time from res;
    querycounts:{?[`res; enlist (=; `u; enlist x); 0b; (enlist `queries)!(enlist `queries)]}'[clients];
    querycountsn:{x xcol y}'[clients; querycounts];
    querycountsnk:{`time xkey ![x;();0b;(enlist `time)!enlist (raze; (each; raze; `time))]}'[querycountsn];
    peakusage:0!(lj/)(querycountsnk);
    
    :update time:.z.d + time from peakusage;
    };

LongestRunning:{
    clients:GetClients[];
    query:"select time, runtime, u, cmd from usage where u in ", (.Q.s1 clients), ", runtime=max runtime";
    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryrdb;
    res:handle query;

    :ParseCmd res;
    };

LongestRunningHeatMap:{
    clients:GetClients[];
    query:"select time:.z.d + 10 xbar time.minute, runtime, u, cmd from usage where u in ", (Q.s1 clients), ", runtime=(max; runtime) fby 10 xbar time.minute";
    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryrdb;
    res:handle query;

    :ParseCmd res;
    };
