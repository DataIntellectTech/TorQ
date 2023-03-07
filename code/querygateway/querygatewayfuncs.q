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

GetUsersRDB:{
    query:"select cmd from usage where u=`gateway";
    handle:GetHandle `queryrdb;
    res:raze last .async.deferred[handle; query];
    resparsed:ParseCmd res;

    users:first value flip select distinct originaluser from resparsed;
    :realusers:users except .usage.ignoreusers;
    };

GetUsersHDB:{[date]
    query:"select cmd from usage where date=", (.Q.s1 date), ", u=`gateway";
    handle:GetHandle `queryhdb;
    res:raze last .async.deferred[handle; query];
    resparsed:ParseCmd res;

    users:first value flip select distinct originaluser from resparsed;
    :realusers:users except .usage.ignoreusers;
    };

GetHandle:{[proc]
    :first -1?exec handle from .gw.availableserverstable[1b] where servertype=proc; 
    };

// currently setup to deal with ubiquitous error sting in cmd
// will need updated when the foregoing is fixed
ParseCmd:{[res]
    cmdsplit:@[{select cmd:-2#'";" vs/: cmd from x}; res; {.lg.e[`ParseCmd; "cmd col missing from paramater res, returning input and exiting function"]; :res;}]; 
    remainder:@[{select from (cols[res] except `cmd)#x}; res; ()];

    cmdcolsplit:select originaluser, query from @[cmdsplit; `originaluser`query; :; flip cmdsplit`cmd];
    cmdcolsplitparsed:update originaluser:`$1_'originaluser, query:1_'-3_'query from cmdcolsplit;

    if [0=count remainder; :cmdcolsplitparsed;];

    :remainder,'cmdcolsplitparsed;
    };

ProcPickerRDB:{[process]
    $[process=`all;
        phrase:"proctype=`rdb";
        phrase:"procname=", .Q.s1 process];

    :phrase;
    };

ProcPickerHDB:{[process]
    $[process=`all;
        phrase:"proctype=`hdb";
        phrase:"procname=", .Q.s1 process];

    :phrase;
    };

QueryCountsRealtime:{[process] 
    users:GetUsersRDB[]; 
    procphrase:ProcPickerRDB[`$process]; 
    
    query:"select from usage where u=`gateway, status=", (.Q.s1 "c"), ", ", procphrase; 
    handle:GetHandle `queryrdb; 
    res:raze last .async.deferred[handle; query]; 
    
    :select count i from ParseCmd[res] where originaluser in users; 
    };

QueryUserCountsRealtime:{[process]
    users:GetUsersRDB[];
    procphrase:ProcPickerRDB[`$process];

    query:"select from usage where u=`gateway, status=", (.Q.s1 "c"), ", ", procphrase;
    handle:GetHandle `queryrdb;
    res:raze last .async.deferred[handle; query];

    :select queries:count i by originaluser from ParseCmd[res] where originaluser in users;
    };

QueryCountsHistorical:{[date; process]
    users:GetUsersHDB[date];
    procphrase:ProcPickerHDB[`$process];

    $[.z.d<=date; query:(); // log error
        1=count date; query:"select from usage where date=", (.Q.s1 date), ", u=`gateway, status=", (.Q.s1 "c"), ", ", procphrase;
        2=count date; query:"select queries:count i from usage where date within (", (.Q.s1 first date), "; ", (.Q.s1 last date), "),", ", u=`gateway, status=", (.Q.s1 "c"), ", ", procphrase;
        // log error
        query:()]

    handle:GetHandle `queryhdb;
    res:raze last .async.deferred[handle; raze query];

    :select queries:count i from ParseCmd[res] where originaluser in users;
    };

QueryUserCountsHistorical:{[date; process]
    users:GetUsersHDB[date];
    procphrase:ProcPickerHDB[`$process];

    $[.z.d<=date; query:(); // log error
        1=count date; query:"select from usage where date=", (.Q.s1 date), ", u=`gateway, status=", (.Q.s1 "c"), ", ", procphrase;
        2=count date; query:"select from usage where date within (", (.Q.s1 first date), "; ", (.Q.s1 last date), ")", ", u=`gateway, status=", (.Q.s1 "c"), ", ", procphrase;
        // log error
        query:()]

    handle:GetHandle `queryhdb;
    res:raze last .async.deferred[handle; raze query];

    :select queries:count i by originaluser from ParseCmd[res] where originaluser in users;
    };

PeakUsage:{[process]
    users:GetUsersRDB[];
    procphrase:ProcPickerRDB[`$process];

    query:"select time, cmd from usage where u=`gateway, status=", (.Q.s1 "c"), ", ", procphrase;
    handle:GetHandle `queryrdb;
    res:raze last .async.deferred[handle; query];

    resparsed:`time xcol 0!select queries:count i by 10 xbar time.minute, originaluser from ParseCmd[res] where originaluser in users;

    // select separate tables of times and queries for each user
    getquerycounts:{[resparsed; users] ?[resparsed; enlist(in; `originaluser; `users); 0b; (`time`queries)!(`time`queries)]}[resparsed; ];
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
    procphrase:ProcPickerRDB[`$process]; 
    
    query:"select time, runtime, proctype, procname, cmd from usage where u=`gateway, status=", (.Q.s1 "c"), ", ", procphrase; 
    handle:GetHandle `queryrdb; 
    res:raze last .async.deferred[handle; query]; 
    resparsed:ParseCmd[res]; 
    
    :select time:.z.d + 10 xbar time.minute, runtime, proctype, procname, originaluser, query from resparsed where originaluser in users, runtime=(max; runtime) fby 10 xbar time.minute;
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
    procphrase:ProcPickerRDB[`$process];

    // where status is "c" or "e"
    query:"select status, cmd from usage where u=`gateway, status in ", (string `ce), ", ", procphrase;
    handle:GetHandle `queryrdb;
    res:raze last .async.deferred[handle; query];

    resparsed:ParseCmd[res];

    :select completed:count i where status="c", error:count i where status="e" from resparsed where originaluser in users;
    };

LongestRunning:{[process]
    users:GetUsersRDB[];
    procphrase:ProcPickerRDB[`$process];

    query:"select runtime, cmd from usage where u=`gateway, status=", (.Q.s1 "c"), ", ", procphrase;
    handle:GetHandle `queryrdb;
    res:raze last .async.deferred[handle; query];
    resparsed:ParseCmd[res];

    :select max runtime by originaluser from resparsed where originaluser in users;
    };

LongestRunningHistorical:{[date; process]
    users:GetUsersHDB[date];
    procphrase:ProcPickerHDB[`$process];

    $[.z.d<=date; query:(); // log error
        1=count date; query:"select runtime, cmd from usage where date=", (.Q.s1 date), ", u=`gateway, status=", (.Q.s1 "c"), ", ", procphrase;
        2=count date; query:"select runtime, cmd from usage where date within (", (.Q.s1 first date), "; ", (.Q.s1 last date), ")", ", u=`gateway, status=", (.Q.s1 "c"), ", ", procphrase;
        // log error
        query:()]
    handle:GetHandle `queryhdb;
    res:raze last .async.deferred[handle; query];
    resparsed:ParseCmd[res];

    :select max runtime by originaluser from resparsed where originaluser in users;
    };

QueryErrorPercentageHistorical:{[date; process]
    users:GetUsersHDB[date];
    procphrase:ProcPickerHDB[`$process];

    $[.z.d<=date; query:(); // log error
        // where status is "c" or "e"
        1=count date; query:"select status, cmd from usage where date=", (.Q.s1 date), ", u=`gateway, status in ", (string `ce), ", ", procphrase;
        // where status is "c" or "e"
        2=count date; query:"select status, cmd from usage where date in (", (.Q.s1 first date), "; ", (.Q.s1 last date), "), u=`gateway, status in ", (string `ce), ", ", procphrase;
        // log error
        query:()]
    handle:GetHandle `queryhdb;
    res:raze last .async.deferred[handle; query];
    resparsed:ParseCmd:[res];

    :select completed:count i where status="c", error:count i where status="e" from resparsed where originaluser in users;
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

PeakUsageHistorical:{[date; process]
    users:GetUsersHDB[date];
    procphrase:ProcPickerHDB[`$process];

    query:"select time, cmd from usage where date=", (.Q.s1 date), ", u=`gateway, status=", (.Q.s1 "c"), ", ", procphrase;
    handle:GetHandle `queryhdb;
    res:raze last .async.deferred[handle; query];

    resparsed:`time xcol 0!select queries:count i by 10 xbar time.minute, originaluser from ParseCmd[res] where originaluser in users;

    // select separate tables of times and queries for each user
    getquerycounts:{[resparsed; users] ?[resparsed; enlist(in; `originaluser; `users); 0b; (`time`queries)!(`time`queries)]}[resparsed; ];
    querycounts:getquerycounts'[users];
    // rename 'queries' col with name of user for each table
    querycountsn:{:(`time; y) xcol x;}'[querycounts; users];

    peakusage:0!(pj/)1!'querycountsn;

    :update time:.z.d + time from peakusage;
    };

//LongestRunningHistorical:{[date;process]
//    users:GetUsersHDB[date];
//    query:"select time, runtime, u, cmd from usage where date=", (.Q.s1 date), ", procname in ", (.Q.s1 process), ", u in ", (.Q.s1 users), ", runtime=max runtime";
//    handle:first -1?exec handle from .gw.availableserverstable[1b] where servertype=`queryhdb;
//    res:raze last .async.deferred[handle; query];
//    :ParseCmd res;
//    };

LongestRunningHeatMapHistorical:{[date; process]
    users:GetUsersHDB[date];
    procphrase:ProcPickerHDB[`$process];

    query:"select time, runtime, proctype, procname, cmd from usage where date=", (.Q.s1 date), ", u=`gateway, status=", (.Q.s1 "c"), ", ", procphrase; 
    handle:GetHandle `queryhdb; 
    res:raze last .async.deferred[handle; query]; 
    resparsed:ParseCmd[res]; 
    
    :select time:.z.d + 10 xbar time.minute, runtime, proctype, procname, originaluser, query from resparsed where originaluser in users, runtime=(max; runtime) fby 10 xbar time.minute;
    };
