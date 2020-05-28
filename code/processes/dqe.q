\d .dqe

dqedbdir:@[value;`dqedbdir;`:dqedb];
gmttime:@[value;`gmttime;1b];
partitiontype:@[value;`partitiontype;`date];
getpartition:@[value;`getpartition;
  {{@[value;`.dqe.currentpartition;
    (`date^partitiontype)$(.z.D,.z.d)gmttime]}}];
writedownperiodengine:@[value;`writedownperiodengine;0D01:00:00];

configcsv:@[value;`.dqe.configcsv;first .proc.getconfigfile["dqengineconfig.csv"]];
resultstab:([]procs:`$();funct:`$();table:`$();column:`$();resvalue:`long$());

/- called at every EOD by .u.end
init:{
  .lg.o[`init;"searching for servers"];
  /- Open connection to discovery
  .servers.startupdependent[`dqedb;10];
  /- set timer to call EOD
  .timer.once[.eodtime.nextroll;(`.u.end;.dqe.getpartition[]);"Running EOD on Engine"];
  /- store i numbers of rows to be saved down to DB
  .dqe.tosavedown:()!();
  .dqe.configtimer[];
  st:.dqe.writedownperiodengine+ min .timer.timer[;`periodstart];
  et:.eodtime.nextroll-.dqe.writedownperiodengine;
  .timer.repeat[st;et;.dqe.writedownperiodengine;(`.dqe.writedownengine;`);"Running periodic writedown"];
  .lg.o[`init;"initialization completed"];
  }

/- update results table with results
updresultstab:{[proc;fn;params;tab;resinput]
  .lg.o[`updresultstab;"Updating results for ",(string fn)," from proc ",string proc];
  if[not 11h=abs type params`col; params[`col]:`];
  `.dqe.resultstab insert (proc;fn1:last` vs fn;tab;params`col;resinput);
  s:exec i from .dqe.resultstab where procs=proc,funct=fn1,table=tab,column=params[`col];
  .dqe.tosavedown[`.dqe.resultstab],:s;
  }

qpostback:{[proc;query;params;querytype;result]
  .dqe.updresultstab[first proc;query;params]'[$[`table=querytype;key result;`];value result];
  .lg.o[`qpostback;"Postback successful for ",string first proc];
  }

runquery:{[query;params;querytype;rs]
  temp:(`,(value value query)[1])!(::), params;
  .lg.o[`runquery;"Starting query run for ",string query];
  if[1<count rs;.lg.e[`runquery"error: can only send query to one remote service, trying to send to ",string count rs];:()];
  if[not rs in exec procname from .servers.SERVERS;.lg.e[`runquery;"error: remote service must be a proctype";:()]];

  h:.dqe.gethandles[(),rs];
  .async.postback[h`w;((value query),params);.dqe.qpostback[h`procname;query;temp;querytype]];
  .lg.o[`runquery;"query successfully ran for ",string query];
  }

loadtimer:{[d]
  .lg.o[`dqe;("Loading query - ",(string d[`query])," from config csv into timer table")];
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

writedownengine:{
  if[0=count .dqe.tosavedown`.dqe.resultstab;:()];
  .dqe.savedata[.dqe.dqedbdir;.dqe.getpartition[];.dqe.tosavedown[`.dqe.resultstab];`.dqe;`resultstab];
  /- get handles for DBs that need to reload
  hdbs:distinct raze exec w from .servers.SERVERS where proctype=`dqedb;
  /- send message for DBs to reload
  .dqe.notifyhdb[.os.pth .dqe.dqedbdir]'[hdbs];
  }

\d .

.dqe.currentpartition:.dqe.getpartition[];  /- initialize current partition


.servers.CONNECTIONS:`tickerplant`rdb`hdb`dqedb /- open connections to required procs, need dqedb as some checks rely on info from both dqe and dqedb

/- setting up .u.end for dqe
.u.end:{[pt]
  .lg.o[`dqe;".u.end initiated"];
  .dqe.endofday[.dqe.dqedbdir;.dqe.getpartition[];`resultstab;`.dqe;.dqe.tosavedown[`.dqe.resultstab]];
  /- get handles for DBs that need to reload
  hdbs:distinct raze exec w from .servers.SERVERS where proctype=`dqedb;
  /- send message for DBs to reload
  .dqe.notifyhdb[.os.pth .dqe.dqedbdir]'[hdbs];
  /- clear check function timers
  .timer.removefunc'[exec funcparam from .timer.timer where `.dqe.runquery in' funcparam];
  /- clear writedown timer
  .timer.removefunc'[exec funcparam from .timer.timer where `.dqe.writedownengine in' funcparam];
  /- clear EOD timer
  .timer.removefunc'[exec funcparam from .timer.timer where `.u.end in' funcparam];
  .dqe.currentpartition:pt+1;
  /- Checking whether .eodtime.nextroll is correct as it affects periodic writedown
  if[(`timestamp$.dqe.currentpartition)>=.eodtime.nextroll;
    .eodtime.nextroll:.eodtime.getroll[`timestamp$.dqe.currentpartition];
    .lg.o[`dqe;"Moving .eodtime.nextroll to match current partition"]
    ];
  .lg.o[`dqe;".eodtime.nextroll set to ",string .eodtime.nextroll];
  .dqe.init[];
  .lg.o[`dqe;".u.end finished"];
  };

.dqe.init[]
