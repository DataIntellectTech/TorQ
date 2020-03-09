\d .dqe

configcsv:@[value;`.dqe.configcsv;first .proc.getconfigfile["dqcconfig.csv"]];
dqcdbdir:@[value;`dqcdbdir;`:dqcdb];
detailcsv:@[value;`.dqe.detailcsv;first .proc.getconfigfile["dqedetail.csv"]];
gmttime:@[value;`gmttime;1b];
partitiontype:@[value;`partitiontype;`date];
writedownperiod:@[value;`writedownperiod;0D01:00:00];
getpartition:@[value;`getpartition;
  {{@[value;`.dqe.currentpartition;
    (`date^partitiontype)$(.z.D,.z.d)gmttime]}}];                                                               /-function to determine the partition value
detailcsv:@[value;`.dqe.detailcsv;first .proc.getconfigfile["dqedetail.csv"]];

testing:@[value;`.dqe.testing;0b];                                                                              /- testing varible for unit tests

compcounter:([id:`long$()]counter:`long$();procs:();results:());

init:{                                                                                                          /- this function gets called at every EOD by .u.end
  .lg.o[`init;"searching for servers"];
  .servers.startup[];                                                                                           /- Open connection to discovery
  .api.add .'value each .dqe.readdqeconfig[.dqe.detailcsv;"SB***"];                                             /- add dqe functions to .api.detail
  .dqe.compcounter[0N]:(0N;();());
  
  configtable:([] action:`$(); params:(); proc:(); mode:`$(); starttime:`timespan$(); endtime:`timespan$(); period:`timespan$())

  .timer.once[.eodtime.nextroll;(`.u.end;.dqe.getpartition[]);"Running EOD on Checker"];                        /- set timer to call EOD

  `.dqe.configtable upsert .dqe.readdqeconfig[.dqe.configcsv;"S**SNNN"];                                        /- Set up configtable from csv
  update checkid:til count .dqe.configtable from `.dqe.configtable;
  update starttime:.z.d+starttime from `.dqe.configtable;                                                       /- from timespan to timestamp
  update endtime:?[0W=endtime;0Wp;.z.d+endtime] from `.dqe.configtable;

  .dqe.loadtimer'[.dqe.configtable];

  .dqe.tosavedown:();                                                                                           /- store i numbers of rows to be saved down to DB
  st:.dqe.writedownperiod+exec min starttime from .dqe.configtable;
  et:.eodtime.nextroll-.dqe.writedownperiod;
  .timer.repeat[st;et;.dqe.writedownperiod;(`.dqe.writedown;`);"Running peridotic writedown"];
  }

writedown:{
  if[0=count .dqe.tosavedown;:()];
  .dqe.savedata[.dqe.dqcdbdir;.dqe.getpartition[];.dqe.tosavedown;`.dqe;`results];
  hdbs:distinct raze exec w from .servers.SERVERS where proctype=`dqcdb;                                        /- get handles for DBs that need to reload
  .dqe.notifyhdb[.os.pth .dqe.dqcdbdir]'[hdbs];                                                                 /- send message for DBs to reload
  }
  
dupchk:{[runtype;idnum;params;proc]                                                                             /- checks for unfinished runs that match the new run
  if[params`comp;proc:params`compresproc];
  if[`=proc;:()];
  if[count select from .dqe.results where id=idnum,procschk=proc,chkstatus=`started;
    .dqe.updresultstab[runtype;idnum;0Np;0b;"error:fail to complete before next run";`failed;params;proc]];
  }

initstatusupd:{[runtype;idnum;funct;params;rs]                                                                  /- set initial values in results table
  if[idnum in exec id from .dqe.compcounter;delete from `.dqe.compcounter where id=idnum;];
  .lg.o[`initstatus;"setting up initial record(s) for id ",(string idnum)];
  .dqe.dupchk[runtype;idnum;params]'[rs];                                                                       /- calls dupchk function to check if last runs chkstatus is still started
  vars:params`vars;
  updvars:(key params[`vars]) b:where (),10h=type each value params`vars;
  if[count updvars;vars[updvars]:`$params[`vars] updvars];
  parprint:`$("," sv string (raze/) (),enlist each vars params`fnpar),$[params`comp;",comp(",(string params[`compproc]),",",(string params`compallow),")";""];
  `.dqe.results insert (idnum;funct;parprint;rs[0];rs[1];.z.p;0Np;0b;"";`started;runtype);
  }

updresultstab:{[runtype;idnum;end;res;des;status;params;proc]                                                   /- general function used to update a check in the results table
  .lg.o[`updresultstab;"Updating check id ",(string idnum)," in the results table with status ",string status];
  if[1b=params`comp;proc:params`compresproc];
  if[c:count s:exec i from .dqe.results where id=idnum, procschk=proc,chkstatus=`started;                       /- obtain count of checks that will be updated
    .lg.o[`updresultstab;raze "run check id ",(string idnum)," update in results table with check status ",string status];
    `.dqe.results set update endtime:end,result:res,descp:enlist des,chkstatus:status,chkruntype:runtype from .dqe.results where id=idnum,procschk=proc,chkstatus=`started];
    .dqe.tosavedown,:s;
  delete from `.dqe.compcounter where id=idnum;
  params:()!();
  }

chkcompare:{[runtype;idnum;params]                                                                              /- function to compare the checks
  if[params[`compcount]<>(d:.dqe.compcounter idnum)`counter;:()];                                               /- checks if all async check results have returned
  .lg.o[`chkcompare;"comparison started with id ",string idnum];
  a:d[`results] where not d[`procs]=params`compproc;                                                            /- obtain all the check returns
  procsforcomp:d[`procs] except params`compproc;
  b:d[`results] where d[`procs]=params`compproc;                                                                /- obtain the check to compare the others to

  if[@[{all 0W=x};first b;0b];                                                                                  /- if error in compare proc then fail check
    .dqe.updresultstab[runtype;idnum;.z.p;0b;"error: error on comparison process";`failed;params;`];:()];
  errorprocs:d[`procs] where (),all each @[{0W=x};d`results;0b];
  if[(count errorprocs)= count d`results;                                                                       /- if error in all comparison procs then fail check
    .dqe.updresultstab[runtype;idnum;.z.p;0b;"error: error with all comparison procs";`failed;params;`];:()];
  $[@[{98h=type raze x};b;0b];                                                                                  /- changes comparison for tables
    [matching:procsforcomp where (), params[`compallow] <= (sum t2)%count t2:100*(sum  t)%count t:$[`error~.[{(all/)=[raze x;raze y]};(a;b);{`error}]; 
      .dqe.updresultstab[runtype;idnum;.z.p;0b;"error: tables are not of the same length";`complete;params;`];
      :()];
     =[raze a;raze b]];
    matching:procsforcomp where all each params[`compallow] >= 100* abs -\:[a;first b]%\:first b];
  notmatching:procsforcomp except errorprocs,matching;
  .lg.o[`chkcompare;"comparison finished with id ",string idnum];

  s:(string params[`compproc])," ";
  if[count errorprocs;s,:" | ";s,: raze"error ",("," sv string errorprocs)];
  if[count notmatching;s,:" | ";s,:raze"no match ",("," sv string notmatching)];
  if[count matching;s,:" | ";s,:raze"match ",("," sv string matching)];

  .lg.o[`chkcompare;"Updating descp of compare process in the results table"];
  resbool:not(count errorprocs)|count notmatching;
  .dqe.updresultstab[runtype;idnum;.z.p;resbool;s;`complete;params;`];
  }

postback:{[runtype;idnum;proc;params;result]                                                                    /- function that updates the results table with the check result
  .lg.o[`postback;"postback successful for id ",(string idnum)," from ",string proc];
  if[params`comp;                                                                                               /- if comparision, add to compcounter table
    .dqe.compcounter[idnum]:(
    1+0^.dqe.compcounter[idnum][`counter];
      .dqe.compcounter[idnum][`procs],proc;
      .dqe.compcounter[idnum][`results],$[3<count result;0W;last result])];                                     /- join result to the list

  if[("e"=first result)&(not params`comp);                                                                      /- checks if error returned from server side;
    .dqe.updresultstab[runtype;idnum;0Np;0b;result;`failed;params;proc];
    :()];

  $[params`comp;                                                                                                /- in comparison run, check if all results have returned
    .dqe.chkcompare[runtype;idnum;params];
    .dqe.updresultstab[runtype;idnum;.z.p;first result;result[1];`complete;params;proc]];
  }

getresult:{[runtype;funct;params;idnum;proc;hand]                                                               /- function that sends the check function over async
  .lg.o[`getresults;raze"send function over to prcess: ",string proc];
  fvars:params[`vars] params`fnpar;
  .async.postback[hand;(funct,$[10h=type fvars;enlist fvars;fvars]);.dqe.postback[runtype;idnum;proc;params]];  /- send function with variables down handle
  }

runcheck:{[runtype;idnum;fn;params;rs]                                                                          /- function used to send other function to test processes
  .lg.o[`runcheck;"Starting check run ",string idnum];
  params[`fnpar]:(value value fn)[1];
  temp:$[1=count params`fnpar;enlist params`fnpar;params[`fnpar]]!$[(10h=type params`vars)|(1=count params`vars);enlist params`vars;params`vars];
  params[`vars]:temp;
  fncheck:` vs fn;
  if[not fncheck[2] in key value .Q.dd[`;fncheck 1];                                                            /- run check to make sure passed in function exists
    .lg.e[`runcheck;"Function ",(string fn)," doesn't exist"];
    :()];

  rs:(),rs;                                                                                                     /- set rs to a list
  h:.dqe.gethandles[rs];
  r:.dqe.fillprocname[rs;h];

  .lg.o[`runcheck;"Checking if comparison check"];
  if[not params`comp;
    .dqe.initstatusupd[runtype;idnum;fn;params]'[r];

    .lg.o[`runcheck;"checking for processes that are not connectable"];
    .dqe.updresultstab[runtype;idnum;0Np;0b;"error:can't connect to process";`failed;params;`];

    procsdown:(h`procname) where 0N = h`w;                                                                      /- checks if any procs didn't get handles
    if[count procsdown;.dqe.updresultstab[runtype;idnum;0Np;0b;"error:process is down or has lost its handle";`failed;params]'[procsdown]];
  ];
  if[params`comp;
    if[(params`compproc) in h`procname;                                                                         /- fail if comparison process is in list of processes to check against
      .lg.e[`runcheck;"Can't compare process with itself"];
      .dqe.updresultstab[runtype;idnum;0Np;0b;"error:compare process can't be compared with itself";`failed;params]'[h`procname];
      :()];

    params,:(enlist `compresproc)!enlist `$"," sv string h`procname;
    comph:.dqe.gethandles[params`compproc];                                                                     /- obtain handle for comparison process
    h:h,'comph;

    proccount:count h`procname;
    params,:(enlist `compcount)!enlist proccount;

    .lg.o[`runcheck;(string params`compcount)," procsess will be checked for this comparison"];
    .dqe.initstatusupd[runtype;idnum;fn;params;(`$"," sv string  r[;0]),params`compresproc];

    if[any[null h`w]|any null r[;1];
      .lg.e[`runcheck;"unable to compare as process down or missing handle"];
      .dqe.updresultstab[runtype;idnum;0Np;0b;"error:unable to compare as process down or missing handle";`failed;params;params`compresproc];
      :()];
   ]
  if[0=count h;.lg.e[`runcheck;"cannot open handle to any given processes"];:()];                               /- check if any handles exist, if not exit function
  .dqe.getresult[runtype;value fn;(),params;idnum]'[h[`procname];h[`w]]
  }

results:([]id:`long$();funct:`$();params:`$();procs:`$();procschk:`$();starttime:`timestamp$();endtime:`timestamp$();result:`boolean$();descp:();chkstatus:`$();chkruntype:`$());

loadtimer:{[DICT]
  DICT[`params]: value DICT[`params];                                                                           /- Accounting for potential multiple parameters
  DICT[`proc]: value DICT[`proc];
  functiontorun:(`.dqe.runcheck;`scheduled;DICT`checkid;.Q.dd[`.dqc;DICT`action];DICT`params;DICT`proc);        /- function that will be used in timer
  $[DICT[`mode]=`repeat;                                                                                        /- Determine whether the check should be repeated
    .timer.repeat[DICT`starttime;DICT`endtime;DICT`period;functiontorun;"Running check on ",string DICT`proc];
    .timer.once[DICT`starttime;functiontorun;"Running check once on ",string DICT`proc]]
  }

reruncheck:{[chkid]                                                                                             /- rerun a check manually
  d:exec action, params, proc from .dqe.configtable where checkid=chkid;
  d[`params]: value d[`params][0];
  d[`proc]: value raze d[`proc];
  .dqe.runcheck[`manual;chkid;.Q.dd[`.dqc;d`action];d`params;d`proc];                                           /- input man argument is `manual or `scheduled indicating manul run is on or off
  }

\d .

.dqe.currentpartition:.dqe.getpartition[];                                                                      /- initialize current partition

.servers.CONNECTIONS:`ALL                                                                                       /- set to nothing so that is only connects to discovery

.u.end:{[pt]                                                                                                    /- setting up .u.end for dqe
  .dqe.endofday[.dqe.dqcdbdir;.dqe.getpartition[];(`results;`configtable);`.dqe;.dqe.tosavedown];
  hdbs:distinct raze exec w from .servers.SERVERS where proctype=`dqcdb;                                        /- get handles for DBs that need to reload
  .dqe.notifyhdb[.os.pth .dqe.dqcdbdir]'[hdbs];                                                                 /- send message for DBs to reload
  .timer.removefunc'[exec funcparam from .timer.timer where `.dqe.runcheck in' funcparam];                      /- clear check function timers
  .timer.removefunc'[exec funcparam from .timer.timer where `.u.end in' funcparam];                             /- clear EOD timer
  .timer.removefunc'[exec funcparam from .timer.timer where `.dqe.writedown in' funcparam];                     /- clear writedown timer
  delete configtable from `.dqe;
  .dqe.init[];
  .dqe.currentpartition:pt+1;
  };

if[not .dqe.testing;.dqe.init[]]
