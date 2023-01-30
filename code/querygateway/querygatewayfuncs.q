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

QueryCountsRealtime:{
    query:"select count i from usage where u in `angus`michael`stephen";
    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryrdb;
    res:handle query;
    :res;
    };

QueryUserCountsRealtime:{
    query:"select queries:count i by u from usage where u in `angus`michael`stephen";
    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryrdb;
    res:handle query;
    :res;
    };

QueryCountsHistorical:{[date]
    $[.z.d<=date; query:(); // log error
        1=count date; query:"select queries:count i from usage where date=", string date, ", u in `angus`michael`stephen";
        2=count date; query:"select queries:count i from usage where date within (", string first date, ";", string last date, "), u in `angus`michael`stephen";
        // log error
        query:()]
    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryhdb;
    res:handle raze query;
    :res;
    };

QueryUserCountsHistorical:{[date]
    $[.z.d<=date; query:(); // log error
        1=count date; query:"select queries:count i by u from usage where date=", string date, ", u in `angus`michael`stephen";
        2=count date; query:"select queries:count i by u from usage where date within (", string first date, ";", string last date, "), u in `angus`michael`stephen";
        // log error
        query:()]
    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryhdb;
    res:handle raze query;
    :res;
    };

PeakUsage:{
    query:"`time xcol 0!select queries:count i by 10 xbar time.minute, u from usage where u in `angus`michael`stephen";
    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryrdb;
    res::handle query; 
    
    time::select distinct time from res;
    querycounts:{?[`res; enlist (=; `u; enlist x); 0b; (enlist `queries)!(enlist `queries)]}'[`angus`michael`stephen];
    querycountsn:{x xcol y}'[`angus`michael`stephen; querycounts];
    querycountsnk:{`time xkey ![x;();0b;(enlist `time)!enlist (raze; (each; raze; `time))]}'[querycountsn];
    peakusage:0!(lj/)(querycountsnk);
    
    :update time:.z.d + time from peakusage;
    };

// if there are multiple queries this just grabs the "first" of them
// assuming this is acceptable given the likelihood of two offensively long queries
// having exactly the same runtime
LongestRunning:{
    query:"select runtime, u, cmd from usage where u in `angus`michael`stephen, runtime=max runtime";
    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryrdb;
    res:handle query;

    cmd:raze value flip select cmd from res;
    r:.z.d + raze value flip select runtime from res;
    u:raze raze value flip select u from res;

    f:`$2_first ";" vs raze cmd;
    q:first next "\"" vs raze cmd;
    p:`$-1_last "`" vs raze cmd;

    :([] runtime:r; user:u; func:enlist f; query:enlist q; proc:enlist p);
    };
