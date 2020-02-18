\d .dqe

dqedbdir:@[value;`dqedbdir;`:dqedb];
gmttime:@[value;`gmttime;1b];
partitiontype:@[value;`partitiontype;`date];
getpartition:@[value;`getpartition;
  {{@[value;`.dqe.currentpartition;
    (`date^partitiontype)$(.z.D,.z.d)gmttime]}}];

configcsv:@[value;`.dqe.configcsv;first .proc.getconfigfile["dqengineconfig.csv"]];
resultstab:([]procs:`$();funct:`$();table:`$();column:`$();resvalue:`long$());

init:{
  .lg.o[`init;"searching for servers"];
  .servers.startup[];                                                                                           /- Open connection to discovery
  }

updresultstab:{[proc;fn;params;tab;resinput]                                                                    /- upadate results table with results
  .lg.o[`updresultstab;"Updating results for ",(string fn)," from proc ",string proc];
  if[not 11h=abs type params`col; params[`col]:`];
  `.dqe.resultstab insert (proc;`$5_string fn;tab;params`col;resinput)
  }

qpostback:{[proc;query;params;querytype;result]
  .lg.o[`qpostback;"Postback sucessful for ",string first proc];
  .dqe.updresultstab[first proc;query;params]'[$[`table=querytype;key result;0N];value result];
  }

runquery:{[query;params;querytype;rs]
  temp:(`,(value value query)[1])!(::), params;
  .lg.o[`runquery;"Starting query run for ",string query];
  if[1<count rs;.lg.e[`runquery"error: can only send query to one remote service, trying to send to ",string count rs];:()];
  if[not rs in exec procname from .servers.SERVERS;.lg.e[`runquery;"error: remote service must be a proctype";:()]];

  h:.dqe.gethandles[(),rs];
  .async.postback[h`w;((value query),params);.dqe.qpostback[h`procname;query;temp;querytype]];
  }

loadtimer:{[d]
  d[`params]:value d[`params];
  d[`proc]:value raze d[`proc];
  functiontorun:(`.dqe.runquery;.Q.dd[`.dqe;d`query];d`params;d`querytype;d`proc);
  .timer.once[d`starttime;functiontorun;("Running check on ",string d[`proc])]
  }

configtimer:{[]
  t:.dqe.readdqeconfig[.dqe.configcsv;"S**SN"];
  t:update starttime:.z.d+starttime from t;
  {.dqe.loadtimer[x]}each t
  }
  
anomalychk:{[t;colslist;thres]                                                                                  /-function to check percentage of anomalies in each column from colslist of a table t
  d:({sum{any x~'(0w;-0w;0W;-0W)}'[x]}each flip tt)*100%count tt:((),colslist)#t;
  res:([] colsnames:key d; anomalypercentage:value d);
  update thresholdfail:anomalypercentage>thres from res                                                         /- compare each column's anomalies percentage with threshold thres
  }

dfilechk:{[tname;dirname]                                                                                       /- function to check .d file. Sample use: .dqe.dfilechk[`trade;getenv `KDBHDB]
  system"l ",dirname;
  if[not `PV in key`.Q;
    .lg.o[`dfilechk;"The directory is not partitioned"]; :0b];
  if[2>count .Q.PV;
    .lg.o[`dfilechk;"There is only one partition, therefore there are no two .d files to compare"]; :1b];
  u:` sv'.Q.par'[`:.;-2#.Q.PV;tname],'`.d;
  $[0=sum {()~key x} each u;
    [.lg.o[`dfilechk;"Checking if two latest .d files match"]; (~). get each u];
    [.lg.o[`dfilechk;"Two partitions are available but there are no two .d files for the given table to compare"]; 0b]]
  }

datechk:{[dirname]                                                                                              /- function to check date vector contains latest date in an hdb 
  system"l ",dirname;
  if[not `PV in key`.Q;
    .lg.o[`datechk;"The directory is not partitioned"]; :0b];
  if[not `date in .Q.pf;
    .lg.o[`datechk;"date is not a partition field value"]; :0b];
  k:.z.d mod 7;
  $[k in 1 2; last date=.z.d-1+k; last date=.z.d-1]
  }
  
\d .

.dqe.currentpartition:.dqe.getpartition[];                                                                      /- initialize current partition


.servers.CONNECTIONS:`ALL                                                                                       /- set to nothing so that is only connects to discovery

.u.end:{[pt]                                                                                                    /- setting up .u.end for dqe
  .dqe.endofday[.dqe.dqedbdir;.dqe.getpartition[];`resultstab;`.dqe];
  hdbs:distinct raze exec w from .servers.SERVERS where proctype=`dqedb;                                        /- get handles for DB's that need to reload
  .dqe.notifyhdb[1_string .dqe.dqedbdir]'[hdbs];                                                                /- send message for BD's to reload
  .dqe.currentpartition:pt+1;
  };

.dqe.init[]
.dqe.configtimer[]
