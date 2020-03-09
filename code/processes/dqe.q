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

init:{                                                                                                          /- this function gets called at every EOD by .u.end
  .lg.o[`init;"searching for servers"];
  .servers.startup[];                                                                                           /- Open connection to discovery
  .timer.once[.eodtime.nextroll;(`.u.end;.dqe.getpartition[]);"Running EOD on Engine"];                         /- set timer to call EOD
  
  .dqe.configtimer[];
  .dqe.tosavedown:();                                                                                           /- store i numbers of rows to be saved down to DB
  st:.dqe.writedownperiodengine+ min .timer.timer[;`periodstart];
  et:.eodtime.nextroll-.dqe.writedownperiodengine;
  .timer.repeat[st;et;.dqe.writedownperiodengine;(`.dqe.writedown;`);"Running periodic writedown"];
  }

updresultstab:{[proc;fn;params;tab;resinput]                                                                    /- upadate results table with results
  .lg.o[`updresultstab;"Updating results for ",(string fn)," from proc ",string proc];
  if[not 11h=abs type params`col; params[`col]:`];
  `.dqe.resultstab insert (proc;`$5_string fn;tab;params`col;resinput);
  .dqe.tosavedown,:exec i from .dqe.resultstab where procs=proc,funct=fn,table=tab,column=params[`col];
  }

qpostback:{[proc;query;params;querytype;result]
  .lg.o[`qpostback;"Postback sucessful for ",string first proc];
  .dqe.updresultstab[first proc;query;params]'[$[`table=querytype;key result;`];value result];
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

writedownengine:{
  if[0=count .dqe.tosavedown;:()];
  .dqe.savedata[.dqe.dqedbdir;.dqe.getpartition[];.dqe.tosavedown;`.dqe;`resultstab];
  hdbs:distinct raze exec w from .servers.SERVERS where proctype=`dqedb;                                        /- get handles for DBs that need to reload
  .dqe.notifyhdb[.os.pth .dqe.dqedbdir]'[hdbs];                                                                 /- send message for DBs to reload
  }

\d .

.dqe.currentpartition:.dqe.getpartition[];                                                                      /- initialize current partition


.servers.CONNECTIONS:`ALL                                                                                       /- set to nothing so that is only connects to discovery

.u.end:{[pt]                                                                                                    /- setting up .u.end for dqe
  .dqe.endofday[.dqe.dqedbdir;.dqe.getpartition[];`resultstab;`.dqe;.dqe.tosavedown];
  hdbs:distinct raze exec w from .servers.SERVERS where proctype=`dqedb;                                        /- get handles for DBs that need to reload
  .dqe.notifyhdb[.os.pth .dqe.dqedbdir]'[hdbs];                                                                 /- send message for DBs to reloadi
  .timer.removefunc'[exec funcparam from .timer.timer where `.dqe.runcheck in' funcparam];                      /- clear check function timers
  .timer.removefunc'[exec funcparam from .timer.timer where `.u.end in' funcparam];                             /- clear EOD timer
  .timer.removefunc'[exec funcparam from .timer.timer where `.dqe.writedownengine in' funcparam];               /- clear writedown timer
  .dqe.init[];
  .dqe.currentpartition:pt+1;
  };

.dqe.init[]
