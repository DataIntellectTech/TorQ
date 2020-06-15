\d .dqe

configcsv:@[value;`.dqe.configcsv;first .proc.getconfigfile["dqcconfig.csv"]];
dqcdbdir:@[value;`dqcdbdir;`:dqcdb];
detailcsv:@[value;`.dqe.detailcsv;first .proc.getconfigfile["dqedetail.csv"]];
gmttime:@[value;`gmttime;1b];
partitiontype:@[value;`partitiontype;`date];
writedownperiod:@[value;`writedownperiod;0D01:00:00];
.servers.CONNECTIONS:`tickerplant`rdb`hdb`dqe`dqedb // set to all so that it connects to everything
/.servers.CONNECTIONS:`ALL // set to all so that it connects to everything

/- determine the partition value
getpartition:@[value;`getpartition;
  {{@[value;`.dqe.currentpartition;
    (`date^partitiontype)$(.z.D,.z.d)gmttime]}}];
detailcsv:@[value;`.dqe.detailcsv;first .proc.getconfigfile["dqedetail.csv"]];

testing:@[value;`.dqe.testing;0b];      /- testing varible for unit tests

compcounter:([id:`long$()]counter:`long$();procs:();results:());

/- called at every EOD by .u.end
init:{
  .lg.o[`init;"searching for servers"];
  /- Open connection to discovery. Retry until connected to dqe.
  .servers.startupdependent[`dqedb; 30];
  /- set timer to call EOD
  .timer.once[.eodtime.nextroll;(`.u.end;.dqe.getpartition[]);"Running EOD on Checker"];
  /- add dqe functions to .api.detail
  .api.add .'value each .dqe.readdqeconfig[.dqe.detailcsv;"SB***"];
  .dqe.compcounter[0N]:(0N;();());

  configtable:([] action:`$(); params:(); proc:(); mode:`$(); starttime:`timespan$(); endtime:`timespan$(); period:`timespan$())

  /- Set up configtable from csv
  `.dqe.configtable upsert .dqe.readdqeconfig[.dqe.configcsv;"S**SNNN"];
  update checkid:til count .dqe.configtable from `.dqe.configtable;
  /- from timespan to timestamp
  update starttime:.z.d+starttime from `.dqe.configtable;
  update endtime:?[0W=endtime;0Wp;.z.d+endtime] from `.dqe.configtable;

  .dqe.loadtimer'[.dqe.configtable];

  /- store i numbers of rows to be saved down to DB
  .dqe.tosavedown:()!();
  .lg.o[`.dqc.init; "Starting EOD writedown."];
  /- Checking if .eodtime.nextroll is correct
  if[.z.p>.eodtime.nextroll:.eodtime.getroll[.z.p];system"t 0";.lg.e[`init; "Next roll is in the past."]]
  st:.dqe.writedownperiod+exec min starttime from .dqe.configtable;
  et:.eodtime.nextroll-.dqe.writedownperiod;
  /- Log the start and end times.
  .lg.o[`.dqe.init; "Start time: ",(string st),". End time: ",string et];
  .timer.repeat[st;et;.dqe.writedownperiod;(`.dqe.writedown;`);"Running periodic writedown for results"];
  .timer.repeat[st;et;.dqe.writedownperiod;(`.dqe.writedownconfig;`);"Running periodic writedown for configtable"];
  .lg.o[`init;"initialization completed"];
  }

writedown:{
  if[0=count .dqe.tosavedown`.dqe.results;:()];
  .dqe.savedata[.dqe.dqcdbdir;.dqe.getpartition[];.dqe.tosavedown`.dqe.results;`.dqe;`results];
  /- get handles for DBs that need to reload
  hdbs:distinct raze exec w from .servers.SERVERS where proctype=`dqcdb;
  /- send message for DBs to reload
  .dqe.notifyhdb[.os.pth .dqe.dqcdbdir]'[hdbs];
  }

writedownconfig:{
  if[0=count .dqe.tosavedown`.dqe.configtable;:()];
  .dqe.savedata[.dqe.dqcdbdir;.dqe.getpartition[];.dqe.tosavedown`.dqe.configtable;`.dqe;`configtable];
  /- get handles for DBsthat need to reload
  hdbs:distinct raze exec w from .servers.SERVERS where proctype=`dqcdb;
  /- send message for DB
  .dqe.notifyhdb[.os.pth .dqe.dqcdbdir]'[hdbs];
  }

/- checks for unfinished runs that match the new run
dupchk:{[runtype;idnum;params;proc]
  if[params`comp;proc:params`compresproc];
  if[`=proc;:()];
  if[count select from .dqe.results where id=idnum,procschk=proc,chkstatus=`started;
    .dqe.updresultstab[runtype;idnum;0Np;0b;"error:fail to complete before next run";`failed;params;proc]];
  }

/- set initial values in results table
initstatusupd:{[runtype;idnum;funct;params;rs]
  if[idnum in exec id from .dqe.compcounter;delete from `.dqe.compcounter where id=idnum;];
  .lg.o[`initstatus;"setting up initial record(s) for id ",(string idnum)];
  /- calls dupchk function to check if last runs chkstatus is still started
  .dqe.dupchk[runtype;idnum;params]'[rs];
  vars:params`vars;
  updvars:(key params[`vars]) where (),10h=type each value params`vars;
  if[count updvars;vars[updvars]:`$params[`vars] updvars];
  parprint:`$("," sv string (raze/) (),enlist each vars params`fnpar),$[params`comp;",comp(",(string params[`compproc]),",",(string params`compallow),")";""];
  `.dqe.results insert (idnum;funct;parprint;rs[0];rs[1];.proc.cp[];0Np;0b;"";`started;runtype);
  }

/- general function used to update a check in the results table
updresultstab:{[runtype;idnum;end;res;des;status;params;proc]
  if[1b=params`comp;proc:params`compresproc];
  /- obtain count of checks that will be updated
  if[c:count s:exec i from .dqe.results where id=idnum, procschk=proc,chkstatus=`started;
    .lg.o[`updresultstab;raze "run check id ",(string idnum)," update in results table with check status ",string status];
    `.dqe.results set update endtime:end,result:res,descp:enlist des,chkstatus:status,chkruntype:runtype from .dqe.results where id=idnum,procschk=proc,chkstatus=`started];
    .dqe.tosavedown[`.dqe.results],:s;
  delete from `.dqe.compcounter where id=idnum;
  params:()!();
  s2:exec i from .dqe.configtable where checkid=idnum;
  .dqe.tosavedown[`.dqe.configtable]:.dqe.tosavedown[`.dqe.configtable] union s2;
  .lg.o[`updresultstab;"Updated check id ",(string idnum)," in the results table with status ",string status];
  }

/- function to compare the checks
chkcompare:{[runtype;idnum;params]
  /- checks if all async check results have returned
  if[params[`compcount]<>(d:.dqe.compcounter idnum)`counter;:()];
  .lg.o[`chkcompare;"comparison started with id ",string idnum];
  /- obtain all the check returns
  a:d[`results] where not d[`procs]=params`compproc;
  procsforcomp:d[`procs] except params`compproc;
  /- obtain the check to compare the others to
  b:d[`results] where d[`procs]=params`compproc;

  /- if error in compare proc then fail check
  if[@[{all 0W=x};first b;0b];
    .dqe.updresultstab[runtype;idnum;.proc.cp[];0b;"error: error on comparison process";`failed;params;`];:()];
  errorprocs:d[`procs] where (),all each @[{0W=x};d`results;0b];
  /- if error in all comparison procs then fail check
  if[(count errorprocs)= count d`results;
    .dqe.updresultstab[runtype;idnum;.proc.cp[];0b;"error: error with all comparison procs";`failed;params;`];:()];
  matching:procsforcomp where all each params[`compallow] >= 100* abs -\:[a;first b]%\:first b;
  notmatching:procsforcomp except errorprocs,matching;
  .lg.o[`chkcompare;"comparison finished with id ",string idnum];

  s:(string params[`compproc])," ";
  if[count errorprocs;s,:" | ";s,: raze"error ",("," sv string errorprocs)];
  if[count notmatching;s,:" | ";s,:raze"no match ",("," sv string notmatching)];
  if[count matching;s,:" | ";s,:raze"match ",("," sv string matching)];

  .lg.o[`chkcompare;"Updating descp of compare process in the results table"];
  resbool:not(count errorprocs)|count notmatching;
  .dqe.updresultstab[runtype;idnum;.proc.cp[];resbool;s;`complete;params;`];
  }

/- function that updates the results table with the check result
postback:{[runtype;idnum;proc;params;result]
  .lg.o[`postback;"postback successful for id ",(string idnum)," from ",string proc];
  /- if comparision, add to compcounter table
  if[params`comp;
    .dqe.compcounter[idnum]:(
    1+0^.dqe.compcounter[idnum][`counter];
      .dqe.compcounter[idnum][`procs],proc;
       /- join result to the list
      .dqe.compcounter[idnum][`results],$[3<count result;0W;last result])];

    /- checks if error returned from server side;
    if[("e"=first result)&(not params`comp);
    .dqe.updresultstab[runtype;idnum;0Np;0b;result;`failed;params;proc];
    :()];

  /- in comparison run, check if all results have returned
  $[params`comp;
    .dqe.chkcompare[runtype;idnum;params];
    .dqe.updresultstab[runtype;idnum;.proc.cp[];first result;result[1];`complete;params;proc]];
  }

/- function that sends the check function over async
getresult:{[runtype;funct;params;idnum;proc;hand]
  .lg.o[`getresults;raze"Send function over to process: ",string proc];
  fvars:params[`vars] params`fnpar;
  /- send function with variables down handle
  .async.postback[hand;(funct,$[10h=type fvars;enlist fvars;fvars]);.dqe.postback[runtype;idnum;proc;params]];
  }

/- function used to send other function to test processes
runcheck:{[runtype;idnum;fn;params;rs]
  .lg.o[`runcheck;"Starting check run ",string idnum];
  params[`fnpar]:(value value fn)[1];
  temp:$[1=count params`fnpar;enlist params`fnpar;params[`fnpar]]!$[(10h=type params`vars)|(1=count params`vars);enlist params`vars;params`vars];
  params[`vars]:temp;
  fncheck:` vs fn;
  /- run check to make sure passed in function exists
  if[not fncheck[2] in key value .Q.dd[`;fncheck 1];
    .lg.e[`runcheck;"Function ",(string fn)," doesn't exist"];
    :()];

  /- set rs to a list
  rs:(),rs;
  h:.dqe.gethandles[rs];
  r:.dqe.fillprocname[rs;h];

  .lg.o[`runcheck;"Checking if comparison check"];
  if[not params`comp;
    .dqe.initstatusupd[runtype;idnum;fn;params]'[r];

    .lg.o[`runcheck;"checking for processes that are not connectable"];
    if[count select from .dqe.results where id=idnum,procschk=`,chkstatus=`started;
      .dqe.updresultstab[runtype;idnum;0Np;0b;"error:can't connect to process";`failed;params;`];
    ];
    /- checks if any procs didn't get handles
    procsdown:(h`procname) where 0N = h`w;
    if[count procsdown;.dqe.updresultstab[runtype;idnum;0Np;0b;"error:process is down or has lost its handle";`failed;params]'[procsdown]];
  ];
  if[params`comp;
    /- fail if comparison process is in list of processes to check against
    if[(params`compproc) in h`procname;
      .lg.e[`runcheck;"Can't compare process with itself"];
      .dqe.updresultstab[runtype;idnum;0Np;0b;"error:compare process can't be compared with itself";`failed;params]'[h`procname];
      :()];

    params,:(enlist `compresproc)!enlist `$"," sv string h`procname;
    /- obtain handle for comparison process
    comph:.dqe.gethandles[params`compproc];
    h:h,'comph;

    proccount:count h`procname;
    params,:(enlist `compcount)!enlist proccount;

    .lg.o[`runcheck;(string params`compcount)," process will be checked for this comparison"];
    .dqe.initstatusupd[runtype;idnum;fn;params;(`$"," sv string  r[;0]),params`compresproc];

    if[any[null h`w]|any null r[;1];
      .lg.e[`runcheck;"unable to compare as process down or missing handle"];
      .dqe.updresultstab[runtype;idnum;0Np;0b;"error:unable to compare as process down or missing handle";`failed;params;params`compresproc];
      :()];
   ]
  /- check if any handles exist, if not exit function
  if[0=count h;.lg.e[`runcheck;"cannot open handle to any given processes"];:()];
  .dqe.getresult[runtype;value fn;(),params;idnum]'[h[`procname];h[`w]]
  }

results:([]id:`long$();funct:`$();params:`$();procs:`$();procschk:`$();starttime:`timestamp$();endtime:`timestamp$();result:`boolean$();descp:();chkstatus:`$();chkruntype:`$());

loadtimer:{[DICT]
  .lg.o[`dqc;("Loading check - ",(string DICT[`action])," from configtable into timer table")];
  /- Accounting for potential multiple parameters
  DICT[`params]: value DICT[`params];
  DICT[`proc]: value DICT[`proc];
  /- function that will be used in timer
  functiontorun:(`.dqe.runcheck;`scheduled;DICT`checkid;.Q.dd[`.dqc;DICT`action];DICT`params;DICT`proc);
  /- Determine whether the check should be repeated
  $[DICT[`mode]=`repeat;
    .timer.repeat[DICT`starttime;DICT`endtime;DICT`period;functiontorun;"Running check on ",string DICT`proc];
    .timer.once[DICT`starttime;functiontorun;"Running check once on ",string DICT`proc]]
  }

/- rerun a check manually
reruncheck:{[chkid]
  .lg.o[`dqc;"rerunning check ",string chkid];
  d:exec action, params, proc from .dqe.configtable where checkid=chkid;
  .lg.o[`dqc;"re-running check ",(string d`action)," manually"];
  d[`params]:value d[`params] 0;
  d[`proc]:value raze d`proc;
  /- input man argument is `manual or `scheduled indicating manul run is on or off
  .dqe.runcheck[`manual;chkid;.Q.dd[`.dqc;d`action];d`params;d`proc];
  }

\d .

.dqe.currentpartition:.dqe.getpartition[];


/- setting up .u.end for dqe
.u.end:{[pt]
  .lg.o[`end; "Starting dqc end of day process."];
  {.dqe.endofday[.dqe.dqcdbdir;.dqe.getpartition[]];x;`.dqe;.dqe.tosavedown[` sv(`.dqe;x)]}each `results`configtable;
  /- get handles for DBs that need to reload
  hdbs:distinct raze exec w from .servers.SERVERS where proctype=`dqcdb;
  /- send message for DBs to reload
  .dqe.notifyhdb[.os.pth .dqe.dqcdbdir]'[hdbs];
  /- clear check function timers
  .timer.removefunc'[exec funcparam from .timer.timer where `.dqe.runcheck in' funcparam];
  /- clear writedown timer
  .timer.removefunc'[exec funcparam from .timer.timer where `.dqe.writedown in' funcparam];
  /- clear writedownconfig timer
  .timer.removefunc'[exec funcparam from .timer.timer where `.dqe.writedownconfig in' funcparam];
  /- clear .u.end timer
  .timer.removefunc'[exec funcparam from .timer.timer where `.u.end in' funcparam];
  delete configtable from `.dqe;
  .dqe.currentpartition:pt+1;
  /- Checking whether .eodtime.nextroll is correct as it affects periodic writedown
  if[(`timestamp$.dqe.currentpartition)>=.eodtime.nextroll;
    .eodtime.nextroll:.eodtime.getroll[`timestamp$.dqe.currentpartition];
    .lg.o[`dqc;"Moving .eodtime.nextroll to match current partition"]
    ];
  .lg.o[`dqc;".eodtime.nextroll set to ",string .eodtime.nextroll];
  .dqe.init[];
  .lg.o[`end; "Finished dqc end of day process."]
  };

if[not .dqe.testing;
  .lg.o[`dqc;"Initializing dqc for the first time"];
  .dqe.init[];
  ];
