/ - default parameters
\d .dqe

dqedbdir:@[value;`dqedbdir;`:dqedb];                                                // location of dqedb database
utctime:@[value;`utctime;1b];                                                       // define whether the process is on UTC time or not
partitiontype:@[value;`partitiontype;`date];                                        // set type of partition (defaults to `date)
getpartition:@[value;`getpartition;                                                 // determines the partition value
  {{@[value;`.dqe.currentpartition;
    (`date^partitiontype)$(.z.D,.z.d)utctime]}}];
writedownperiodengine:@[value;`writedownperiodengine;0D01:00:00];                   // dqe periodically writes down to dqedb, writedownperiodengine determines the period between writedowns

configcsv:@[value;`.dqe.configcsv;first .proc.getconfigfile["dqengineconfig.csv"]]; // loading up the config csv file
resultstab:([]procs:`$();funct:`$();table:`$();column:`$();resvalue:`long$());      // schema for the resultstab that shows query results
advancedres:([]procs:`$();funct:`$();table:`$();resultkeys:`$();resultdata:());
/ - end of default parameters


/- called at every EOD by .u.end
init:{
  .lg.o[`init;"searching for servers"];
  /- Open connection to discovery
  .servers.startupdependent[`dqedb;10];
  if[.dqe.utctime=1b;.eodtime.nextroll:.eodtime.getroll[`timestamp$.dqe.currentpartition]+(.z.T-.z.t)];
  /- set timer to call EOD
  .timer.once[.eodtime.nextroll;(`.u.end;.dqe.getpartition[]);"Running EOD on Engine"];
  /- store i numbers of rows to be saved down to DB
  .dqe.tosavedown:()!();
  .dqe.configtimer[];
  st:.dqe.writedownperiodengine+min .timer.timer[;`periodstart];
  et:.eodtime.nextroll-.dqe.writedownperiodengine;
  if[((.z.Z,.z.z).dqe.utctime)>st;st:((.z.Z,.z.z).dqe.utctime)+.dqe.writedownperiodengine];
  .lg.o[`init;"start time of periodic writedown is: ",string st];
  .lg.o[`init;"end time of periodic writedown is: ",string et];
  .timer.repeat[st;et;.dqe.writedownperiodengine;(`.dqe.writedownengine;`);"Running periodic writedown on resultstab"];
  .timer.repeat[st;et;.dqe.writedownperiodengine;(`.dqe.writedownadvanced;`);"Running periodic writedown on advancedres"];
  .lg.o[`init;"initialization completed"];
  }

/- update results table with results
updresultstab:{[proc;fn;params;reskeys;resinput]
  .lg.o[`updresultstab;"Updating results for ",(string fn)," from proc ",string proc];
  if[-7h=type resinput;
    if[not 11h=abs type params`col; params[`col]:`];
    `.dqe.resultstab insert (proc;fn1:last` vs fn;reskeys;params`col;resinput);
    s:exec i from .dqe.resultstab where procs=proc,funct=fn1,table=reskeys,column=params[`col];
    .dqe.tosavedown[`.dqe.resultstab],:s;]
  if[-7h<>type resinput;
    if[not 11=abs type params`tab;params[`tab]:`];
    `.dqe.advancedres insert (proc;fn1:last` vs fn;params`tab;reskeys;resinput);
    s:exec i from .dqe.advancedres where procs=proc,funct=fn1,table=params[`tab],resultkeys=reskeys;
    .dqe.tosavedown[`.dqe.advancedres],:s;]
  }

qpostback:{[proc;query;params;querytype;result]
  .dqe.updresultstab[first proc;query;params]'[$[`table=querytype;key result;`];value result];
  .lg.o[`qpostback;"Postback successful for ",string first proc];
  }

/- sends queries to test processes
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

/- adds today's date to the time from config csv, before loading the queries to the timer
configtimer:{[]
  t:.dqe.readdqeconfig[.dqe.configcsv;"S**SN"];
  t:update starttime:(`date$(.z.D,.z.d).dqe.utctime)+starttime from t;
  {.dqe.loadtimer[x]}each t
  }

writedownengine:{
  if[0=count .dqe.tosavedown`.dqe.resultstab;:()];
  dbprocs:exec distinct procname from raze .servers.getservers[`proctype;;()!();0b;1b]each`hdb`dqedb`dqcdb;  // Get a list of all databases.
  restemp1:select from .dqe.resultstab where procs in dbprocs;
  restemp2:select from .dqe.resultstab where not procs in dbprocs;
  restemp3:.dqe.resultstab;
  .dqe.resultstab::restemp1;
  .dqe.savedata[.dqe.dqedbdir;.dqe.getpartition[]-1;.dqe.tosavedown[`.dqe.resultstab];`.dqe;`resultstab];
  .dqe.resultstab::restemp2;
  .dqe.savedata[.dqe.dqedbdir;.dqe.getpartition[];.dqe.tosavedown[`.dqe.resultstab];`.dqe;`resultstab];
  .dqe.resultstab::restemp3;
  /- get handles for DBs that need to reload
  hdbs:distinct raze exec w from .servers.SERVERS where proctype=`dqedb;
  /- send message for DBs to reload
  .dqe.notifyhdb[.os.pth .dqe.dqedbdir]'[hdbs];
  }

writedownadvanced:{
  if[0=count .dqe.tosavedown`.dqe.advancedres;:()];
  dbprocs:exec distinct procname from raze .servers.getservers[`proctype;;()!();0b;1b]each`hdb`dqedb`dqcdb;  // Get a list of all databases.
  advtemp1:select from .dqe.advancedres where procs in dbprocs;
  advtemp2:select from .dqe.advancedres where not procs in dbprocs;
  advtemp3:.dqe.advancedres;
  .dqe.advancedres::advtemp1;
  .dqe.savedata[.dqe.dqedbdir;.dqe.getpartition[]-1;.dqe.tosavedown[`.dqe.advancedres];`.dqe;`advancedres];
  .dqe.advancedres::advtemp2:
  .dqe.savedata[.dqe.dqedbdir;.dqe.getpartition[];.dqe.tosavedown[`.dqe.advancedres];`.dqe;`advancedres];
  .dqe.advancedres::advtemp3;
  /- get handles for DBs that need to reload
  hdbs:distinct raze exec w from .servers.SERVERS where proctype=`dqedb;
  /- send message for DBs to reload
  .dqe.notifyhdb[.os.pth .dqe.dqedbdir]'[hdbs];
  }

\d .

.dqe.currentpartition:.dqe.getpartition[];  /- initialize current partition


.servers.CONNECTIONS:`tickerplant`rdb`hdb`dqedb`dqcdb /- open connections to required procs, need dqedb as some checks rely on info from both dqe and dqedb

/- setting up .u.end for dqe
.u.end:{[pt]
  .lg.o[`dqe;".u.end initiated"];
  dbprocs:exec distinct procname from raze .servers.getservers[`proctype;;()!();0b;1b]each`hdb`dqedb`dqcdb;  // Get a list of all databases.
  restemp1:select from .dqe.resultstab where procs in dbprocs;
  restemp2:select from .dqe.resultstab where not procs in dbprocs;
  advtemp1:select from .dqe.advancedres where procs in dbprocs;
  advtemp2:select from .dqe.advancedres where not procs in dbprocs;
  .dqe.resultstab::restemp1;
  .dqe.advancedres::advtemp1;
  {.dqe.endofday[.dqe.dqedbdir;.dqe.getpartition[]-1;x;`.dqe;.dqe.tosavedown[` sv(`.dqe;x)]]}each`resultstab`advancedres;
  .dqe.resultstab::restemp2;
  .dqe.advancedres::advtemp2;
  {.dqe.endofday[.dqe.dqedbdir;.dqe.getpartition[];x;`.dqe;.dqe.tosavedown[` sv(`.dqe;x)]]}each`resultstab`advancedres;
  /- get handles for DBs that need to reload
  hdbs:distinct raze exec w from .servers.SERVERS where proctype=`dqedb;
  /- check list of handles to DQEDBs is non-empty, we need at least one to
  /- notify DQEDB to reload
  if[0=count hdbs;.lg.e[`.u.end; "No handles open to the DQEDB, cannot notify DQEDB to reload."]];
  /- send message for DBs to reload
  .dqe.notifyhdb[.os.pth .dqe.dqedbdir]'[hdbs];
  /- clear check function timers
  .timer.removefunc'[exec funcparam from .timer.timer where `.dqe.runquery in' funcparam];
  /- clear writedown timer on resultstab
  .timer.removefunc'[exec funcparam from .timer.timer where `.dqe.writedownengine in' funcparam];
  /- clear writedown timer on advancedres
  .timer.removefunc'[exec funcparam from .timer.timer where `.dqe.writedownadvanced in' funcparam];
  /- clear EOD timer
  .timer.removefunc'[exec funcparam from .timer.timer where `.u.end in' funcparam];
  .lg.o[`dqe;"removed functions from .timer.timer, .u.end continues"];
  .dqe.currentpartition:pt+1;
   /- Checking whether .eodtime.nextroll is correct as it affects periodic writedown
  if[(`timestamp$.dqe.currentpartition)>=.eodtime.nextroll;
    .eodtime.nextroll:.eodtime.getroll[`timestamp$.dqe.currentpartition];
    .lg.o[`dqe;"Moving .eodtime.nextroll to match current partition"]
    ];
  if[.dqe.utctime=1b;.eodtime.nextroll:.eodtime.getroll[`timestamp$.dqe.currentpartition]+(.z.T-.z.t)];
  .lg.o[`dqe;".eodtime.nextroll set to ",string .eodtime.nextroll];
  .dqe.init[];
  .lg.o[`dqe;".u.end finished"];
  };

.dqe.init[]
