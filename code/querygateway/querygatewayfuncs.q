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

//functions to set up variables
//RealtimeProcs:{};

//HistoricalProcs{};

//HistoricalDates:{};



GetUsers:{
    query:"first value flip select distinct u from .clients.clients where not u in .usage.ignoreusers";
    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`gateway;
    res:handle query;
    if[1=count res; :first res];
    :res;
    };

GetUsersRDB:{
    handle:hopen hsym `$raze"::",string (first -1?exec port from .servers.procstab where proctype=`queryrdb),":querygateway:pass";
    usageusers:handle"first flip select distinct u from usage";
    ignoreusers:`,(`$system"echo $USER"),`admin,exec distinct proctype from .servers.procstab;
    res:usageusers except ignoreusers;
    if[1=count res; :first res];
    :res;
    };

GetUsersHDB:{[date]
    handle:hopen hsym `$raze"::",string (first -1?exec port from .servers.procstab where proctype=`queryhdb),":querygateway:pass";
    usageusers:handle"first flip select distinct u from usage where date=",string date;
    ignoreusers:`,(`$system"echo $USER"),`admin,exec distinct proctype from .servers.procstab;
    res:usageusers except ignoreusers;
    if[1=count res; :first res];
    :res;
    };

ParseCmd:{[res; procpicker]
    $[procpicker;

        [cmdsplit:select cmd:-2#'";" vs/: cmd from res;
            remainder:update runtime:.proc.cd[] + runtime from (cols[res] except `cmd)#res;

            cmdcolsplit:select originaluser, query from @[cmdsplit; `originaluser`query; :; flip cmdsplit`cmd];
            cmdcolsplitparsed:update originaluser:`$1_'originaluser, query:1_'-3_'query from cmdcolsplit;

            :remainder,'cmdcolsplitparsed;];

        [cmdsplit:select cmd from update cmd:";" vs ' cmd from res;
            remainder:update runtime:.proc.cd[] + runtime from (cols[res] except `cmd)#res;

            // split cmd into three columns
            cmdcolsplit:select func, query, proc from @[cmdsplit; `func`query`proc; :; flip cmdsplit`cmd];
            // parse out unwanted chars
            cmdcolsplitparsed:update func:`$2_'func, query:1_'-1_'query, proc:`$1_'-1_'proc from cmdcolsplit;

            :remainder,'cmdcolsplitparsed;] ];
    };

ProcPickerRDB:{[process]
    $[process=`any;
        phrase:"proctype=`rdb";
        phrase:"procname=", .Q.s1 process];

    :phrase;
    };

ProcPickerHDB:{[process]
    $[process=`any;
        phrase:"proctype=`hdb";
        phrase:"procname", .Q.s1 process];

    :phrase;
    };

QueryCountsRealtime:{[process] 
    users:GetUsersRDB[]; 
    procphrase:ProcPickerRDB[`$process]; 
    
    query:"select from usage where u=`gateway, status=", (.Q.s1 "c"), ", ", procphrase; 
    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryrdb; 
    res:raze last .async.deferred[handle; query]; 
    
    :select count i from ParseCmd[res; 1b] where originaluser in users; 
    };

QueryUserCountsRealtime:{[process]
    users:GetUsersRDB[];
    procphrase:ProcPickerRDB[`$process];

    query:"select from usage where u=`gateway, status=", (.Q.s1 "c"), ", ", procphrase;
    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryrdb;
    res:raze last .async.deferred[handle; query];

    :select queries:count i by originaluser from ParseCmd[res; 1b] where originaluser in users;
    };

QueryCountsHistorical:{[date; process]
    users:GetUsersHDB[date];
    procphrase:ProcPickerHDB[`$process]

    $[.z.d<=date; query:(); // log error
        1=count date; query:"select from usage where date=", (.Q.s1 date), ", status=", (.Q.s1 "c"), ", ", procphrase;
        2=count date; query:"select queries:count i from usage where date within (", (.Q.s1 first date), "; ", (.Q.s1 last date), "),", ", status=", (.Q.s1 "c"), ", ", procphrase;
        // log error
        query:()]

    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryhdb;
    res:raze last .async.deferred[handle; raze query];

    :select queries:count i from ParseCmd[res; 1b] where originaluser in users;
    };

QueryUserCountsHistorical:{[date; process]
    users:GetUsersHDB[date];
    procphrase:ProcPickerHDB[`$process];

    $[.z.d<=date; query:(); // log error
        1=count date; query:"select from usage where date=", (.Q.s1 date), ", status=", (.Q.s1 "c"), ", ", procphrase;
        2=count date; query:"select from usage where date within (", (.Q.s1 first date), "; ", (.Q.s1 last date), ")", ", status=", (.Q.s1 "c"), procphrase;
        // log error
        query:()]

    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryhdb;
    res:raze last .async.deferred[handle; raze query];

    :select queries:count i by originaluser from ParseCmd[res; 1b] where originaluser in users;
    };

PeakUsage:{[process]
    users:GetUsersRDB[];
    query:"`time xcol 0!select queries:count i by 10 xbar time.minute, u from usage where u in ", (.Q.s1 users), ", status=", (.Q.s1 "c"), ", procname in ", (.Q.s1 process);
    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryrdb;
    res:raze last .async.deferred[handle; query];

    // select separate table of times and queries for each user
    getquerycounts:{[res; users] ?[res; enlist(=; `u; `users); 0b; (`time`queries)!(`time`queries)]}[res; ];
    querycounts:getquerycounts'[users];
    // rename 'queries' col with name of user for each table
    querycountsn:{:(`time; y) xcol x;}'[querycounts; users];

    peakusage:0!(pj/)1!'querycountsn;

    :update time:.z.d + time from peakusage;
    };

//LongestRunning:{[process]
//    users:GetUsersRDB[];
//    query:"select time, runtime, u, cmd from usage where procname in ", (.Q.s1 process), ", u in ", (.Q.s1 users), ", runtime=max runtime";
//    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryrdb;
//    res:raze last .async.deferred[handle; query];
//    :ParseCmd res;
//    };

LongestRunningHeatMap:{[process]
    users:GetUsersRDB[];
    query:"select time:.z.d + 10 xbar time.minute, runtime, u, cmd from usage where u in ", (.Q.s1 users), ", status=", (.Q.s1 "c"), ", procname in ", (.Q.s1 process), ", runtime=(max; runtime) fby 10 xbar time.minute";
    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryrdb;
    res:raze last .async.deferred[handle; query];

    :ParseCmd[res; 0b];
    };

//Return percentage of queries that were successful by user
//QueryErrorPercentage:{[process]
//    users:GetUsersRDB[];
//    query:"select completed:100*(count i where status=\"c\")%(count i where status=\"c\")+count i where status=\"e\" by u from usage where procname in ", (.Q.s1 process), ", u in ", (.Q.s1 users);
//    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryrdb;
//    res:raze last .async.deferred[handle; query];
//    :res;
//    };

QueryErrorPercentage:{[process]
    users:GetUsersRDB[];
    query:"select completed:count i where status=\"c\", error:count i where status=\"e\" by u from usage where procname in ", (.Q.s1 process), ", u in ", (.Q.s1 users);
    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryrdb;
    res:raze last .async.deferred[handle; query];
    :res;
    };

LongestRunning:{[process]
    users:GetUsersRDB[];
    query:"select max runtime by u from usage where u in ", (.Q.s1 users), ", status=", (.Q.s1 "c"), ", procname in ", (.Q.s1 process);
    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryrdb;
    res:raze last .async.deferred[handle; query];
    :res;
    };

LongestRunningHistorical:{[date;process]
    users:GetUsersHDB[date];
    $[.z.d<=date; query:(); // log error
        1=count date; query:"select max runtime by u from usage where date=", (.Q.s1 date), ", u in ", (.Q.s1 users), ", status=", (.Q.s1 "c"), ", procname in ", (.Q.s1 process);
        2=count date; query:"select max runtime by u from usage where date within (", (.Q.s1 first date), "; ", (.Q.s1 last date), ")", ", u in ", (.Q.s1 users), ", status=", (.Q.s1 "c"), " , procname in ", (.Q.s1 process);
        // log error
        query:()]
    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryhdb;
    res:raze last .async.deferred[handle; query];
    :res;
    };

QueryErrorPercentageHistorical:{[date;process]
    users:GetUsersHDB[date];
    $[.z.d<=date; query:(); // log error
        1=count date; query:"select completed:count i where status=\"c\", error:count i where status=\"e\" by u from usage where date=", (.Q.s1 date), ", procname in ", (.Q.s1 process), ", u in ", (.Q.s1 users);
        2=count date; query:"select completed:count i where status=\"c\", error:count i where status=\"e\" by u from usage where date within (", (.Q.s1 first date), "; ", (.Q.s1 last date), "), procname in ", (.Q.s1 process), ", u in ", (.Q.s1 users);
        // log error
        query:()]
    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryhdb;
    res:raze last .async.deferred[handle; query];
    :res;
    };

//Return queries which take longer than given runtime input, t
//t in milliseconds 10^-3
LongQuery:{[t]
    users:GetUsers[];
    timens:t*1000000; //Convert to nano seconds
    query:"select from usage where runtime>", (.Q.s1 timens), ", u in ", (.Q.s1 users);
    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryrdb;
    res:raze last .async.deferred[handle; query];
    :res;
    };

//Number of distinct users
NumberOfUsers:{
    users:GetUsers[];
    query:"select count distinct u from usage where u in ", (.Q.s1 users);
    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryrdb;
    res:raze last .async.deferred[handle; query];
    :res;
    };

PeakUsageHistorical:{[date;process]
    users:GetUsersHDB[date];
    query:"`time xcol 0!select queries:count i by 10 xbar time.minute, u from usage where date=", (.Q.s1 date), ", u in ", (.Q.s1 users), ", status=", (.Q.s1 "c"), ", procname in ", (.Q.s1 process);
    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryhdb;
    res:raze last .async.deferred[handle; query];

    time:select distinct time from res;

    getquerycounts:{[res; users] ?[res; enlist (=; `u; enlist users); 0b; (enlist `queries)!(enlist `queries)]}[res; ];
    querycounts:getquerycounts'[users];

    querycountsn:{x xcol y}'[users; querycounts];
    querycountsn:querycountsn where not 0=count each querycountsn;

    getquerycountsnk:{[time; querycountsn] `time xkey ![querycountsn;();0b;(enlist `time)!enlist (raze; (each; raze; `time))]}[time; ];
    querycountsnk:getquerycountsnk'[querycountsn];

    peakusage:0!(lj/)(querycountsnk);

    :update time:date + time from peakusage;
    };

//LongestRunningHistorical:{[date;process]
//    users:GetUsersHDB[date];
//    query:"select time, runtime, u, cmd from usage where date=", (.Q.s1 date), ", procname in ", (.Q.s1 process), ", u in ", (.Q.s1 users), ", runtime=max runtime";
//    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryhdb;
//    res:raze last .async.deferred[handle; query];
//    :ParseCmd res;
//    };

LongestRunningHeatMapHistorical:{[date;process]
    users:GetUsersHDB[date];
    query:"select time:date + 10 xbar time.minute, runtime, u, cmd from usage where date=", (.Q.s1 date), ", u in ", (.Q.s1 users), ", status=", (.Q.s1 "c"), ", procname in ", (.Q.s1 process), ", runtime=(max; runtime) fby 10 xbar time.minute";
    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryhdb;
    res:raze last .async.deferred[handle; query];

    :ParseCmd[res; 0b];
    };

