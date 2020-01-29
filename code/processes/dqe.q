\d .dqe

configcsv:@[value;`.dqe.configcsv;first .proc.getconfigfile["dqeconfig.csv"]];
dqedbdir:@[value;`dqedbdir;`:dqedb];
detailcsv:@[value;`.dqe.detailcsv;first .proc.getconfigfile["dqedetail.csv"]];
gmttime:@[value;`gmttime;1b];
partitiontype:@[value;`partitiontype;`date];
getpartition:@[value;`getpartition;
  {{@[value;`.dqe.currentpartition;
    (`date^partitiontype)$(.z.D,.z.d)gmttime]}}];                                                               /-function to determine the partition value
detailcsv:@[value;`.dqe.detailcsv;first .proc.getconfigfile["dqedetail.csv"]];

testing:@[value;`.dqe.testing;0b];                                                                              /- testing varible for unit tests

compcounter:([id:`long$()]counter:`long$();procs:();results:());

init:{
  .lg.o[`init;"searching for servers"];
  .servers.startup[];                                                                                           /- Open connection to discovery
  .api.add .'value each .dqe.readdqeconfig[.dqe.detailcsv;"SB***"];                                             /- add dqe functions to .api.detail
  }

configtable:([] action:`$(); params:(); proc:(); mode:`$(); starttime:`timespan$(); endtime:`timespan$(); period:`timespan$())

readdqeconfig:{[file;types]
  .lg.o["reading dqe config from ",string file:hsym file];                                                      /- notify user about reading in config csv
  c:.[0:;((types;enlist",");file);{.lg.e["failed to load dqe configuration file: ",x]}]                         /- read in csv, trap error
 }

gethandles:{exec procname,proctype,w from .servers.SERVERS where (procname in x) | (proctype in x)};

fillprocname:{[rs;h]                                                                                            /- fill procname for results table
  val:rs where not rs in raze a:h`proctype`procname;
  (flip a),val,'`
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
  parprint:`$("," sv string (raze/) (),params[`vars] params`fnpar),$[params`comp;",comp(",(string params[`compproc]),",",(string params`compallow),")";""];
  `.dqe.results insert (idnum;funct;parprint;rs[0];rs[1];.z.p;0Np;0b;"";`started;runtype);
  }

updresultstab:{[runtype;idnum;end;res;des;status;params;proc]                                                   /- general function used to update a check in the results table
  .lg.o[`updresultstab;"Updating check id ",(string idnum)," in the results table with status ",string status];
  if[1b=params`comp;proc:params`compresproc];
  if[c:count select from .dqe.results where id=idnum, procschk=proc,chkstatus=`started;                         /- obtain count of checks that will be updated
    .lg.o[`updresultstab;raze "run check id ",(string idnum)," update in results table with check status ",string status];
    `.dqe.results set update endtime:end,result:res,descp:enlist des,chkstatus:status,chkruntype:runtype from .dqe.results where id=idnum,procschk=proc,chkstatus=`started];
  delete from `.dqe.compcounter where id=idnum;
  params:()!();
  }

chkcompare:{[runtype;idnum;params]                                                                              /- function to compare the checks
  if[params[`compcount]<>(d:.dqe.compcounter idnum)`counter;:()];                                               /- checks if all async check results have returned
  .lg.o[`chkcompare;"comparison started with id ",string idnum];
  a:d[`results] where not d[`procs]=params`compproc;                                                            /- obtain all the check returns
  procsforcomp:d[`procs] except params`compproc;
  b:d[`results] where d[`procs]=params`compproc;                                                                /- obtain the check to compare the others to

  if[all 0W=first b;                                                                                            /- if error in compare proc then fail check
    .dqe.updresultstab[runtype;idnum;.z.p;0b;"error: error on comparison process";`failed;params;`];:()];
  errorprocs:d[`procs] where all each 0W=d`results;
  if[(count errorprocs)= count d`results;                                                                       /- if error in all comparison procs then fail check
    .dqe.updresultstab[runtype;idnum;.z.p;0b;"error: error with all comparison procs";`failed;params;`];:()];
  matching:procsforcomp where all each params[`compallow] >= 100* abs -\:[a;first b]%\:first b;
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

nullchk:{[t;colslist;thres]                                                                                     /- function to check percentage of nulls in each column from colslist of a table t
  d:({sum$[0h=type x;0=count@'x;null x]}each flip tt)*100%count tt:((),colslist)#t;                             /- dictionary of nulls percentages for each column
  res:([] colsnames:key d; nullspercentage:value d);
  update thresholdfail:nullspercentage>thres from res                                                           /- compare each column's nulls percentage with threshold thres
  }

anomalychk:{[t;colslist;thres]                                                                                  /-function to check percentage of anomalies in each column from colslist of a table t
  d:({sum{any x~'(0w;-0w;0W;-0W)}'[x]}each flip tt)*100%count tt:((),colslist)#t;
  res:([] colsnames:key d; anomalypercentage:value d);
  update thresholdfail:anomalypercentage>thres from res                                                         /- compare each column's anomalies percentage with threshold thres
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

hdbtabchk:{[table]
  if[count b:where (),(11h=abs type table) & (table in .Q.pt);                                                  /- checks if any variable for check function is type symbol
    .lg.o[`containerfn;"Table(s) sent to HDB without a where clause"];
    .lg.o[`containerfn;("," sv string vars b)," have been changed to functional selects with where clause"];
    ?[table;enlist (=;.Q.pf;last .Q.PV);0b;()]]
  }

getresult:{[runtype;funct;params;idnum;proc;hand]                                                               /- function that sends the check function over async
  .lg.o[`getresults;raze"send function over to prcess: ",string proc];
  params[`hdbtabchk]:.dqe.hdbtabchk;
  .async.postback[hand;(funct,params[`vars] params`fnpar);.dqe.postback[runtype;idnum;proc;params]];            /- send function with variables down handle
  }

runcheck:{[runtype;idnum;fn;params;rs]                                                                          /- function used to send other function to test processes
  .lg.o[`runcheck;"Starting check run ",string idnum];
  temp:(raze(`;params[`fnpar]:(value value fn)[1]))!raze (::;params`vars);
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

    if[any[null h`w]|any null r[;1]
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
  functiontorun:(`.dqe.runcheck;`scheduled;DICT`checkid;.Q.dd[`.dqe;DICT`action];DICT`params;DICT`proc);        /- function that will be used in timer
  $[DICT[`mode]=`repeat;                                                                                        /- Determine whether the check should be repeated
    .timer.repeat[DICT`starttime;DICT`endtime;DICT`period;functiontorun;"Running check on ",string DICT`proc];
    .timer.once[DICT`starttime;functiontorun;"Running check once on ",string DICT`proc]]
  }

reruncheck:{[chkid]                                                                                             /- rerun a check manually
  d:exec action, params, proc from .dqe.configtable where checkid=chkid;
  d[`params]: value d[`params][0];
  d[`proc]: value raze d[`proc];
  .dqe.runcheck[`manual;chkid;.Q.dd[`.dqe;d`action];d`params;d`proc];                                           /- input man argument is `manual or `scheduled indicating manul run is on or off
  }

\d .

.dqe.currentpartition:.dqe.getpartition[];                                                                      /- initialize current partition

.servers.CONNECTIONS:`ALL                                                                                       /- set to nothing so that is only connects to discovery

.u.end:{[pt]    /- setting up .u.end for dqe
  .dqe.endofday[.dqe.getpartition[]];
  .dqe.currentpartition:pt+1;
  };

.dqe.init[]

`.dqe.configtable upsert .dqe.readdqeconfig[.dqe.configcsv;"S**SNNN"]                                           /- Set up configtable from csv
update checkid:til count .dqe.configtable from `.dqe.configtable
update starttime:.z.d+starttime from `.dqe.configtable                                                          /- from timespan to timestamp
update endtime:?[0W=endtime;0Wp;.z.d+endtime] from `.dqe.configtable

/ Sample runcheck:
/ show .dqe.results
/ Load up timers

/Sample reruncheck
/chkid:3
/.dqe.reruncheck[chkid]
if[not .dqe.testing;.dqe.loadtimer '[.dqe.configtable]]
