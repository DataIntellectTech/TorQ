//Number of queries on a given process by hour (or any given bucket)
testfunc:{.gw.syncexec[({[x;y]select query_suc:count i by procname from usage where time within (x;y)};x;y);`queryrdb]}
//Number of queries ran by a specific user
//Number of distinct users querying a process
//Return list of queries that run over a given run time
//Return the date range queried on a process


/Number of queries on a given process by hour (or any given bucket)
//d:(`proc`bucket`sd`ed)!(`rdb1:60:.z.d-3;.z.d)
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
         where date within (d[`sd];d[`ed]),u=d[`user];
         select queries_suc:count where status=first string `c,queries_err:count where status=first string `e
         by time.date,procname from usage
         where u=d[`user]]};d);`queryhdb`queryrdb];
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
TimerLimit:{[lim;sd;ed]
   .gw.syncexec[({[lim;sd;ed]
      $[.proc.proctype=`queryhdb;
         select from usage
         where date within (sd;ed),runtime>lim;
         select from usage
         where runtime>lim]};lim;sd;ed);`queryhdb`queryrdb];
 };
