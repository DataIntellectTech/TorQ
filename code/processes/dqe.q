\d .dqe

configcsv:@[value;`.dqe.configcsv;first .proc.getconfigfile["dqeconfig.csv"]];
detailcsv:@[value;`.dqe.detailcsv;first .proc.getconfigfile["dqedetailtab.csv"]];

compcounter:([id:`long$()]counter:`long$();procs:();results:());

init:{
  .lg.o[`init;"searching for servers"];
  .servers.startup[];                                                                                           /- Open connection to discovery
  .api.add .'value each .dqe.readdqeconfig[.dqe.detailcsv;"SB***"];                                             /- add dqe functions to .api.detail
  }

configtable:([] action:`$(); params:(); proc:`$(); mode:`$(); starttime:`timespan$(); endtime:`timespan$(); period:`timespan$())

readdqeconfig:{[file;types]
  .lg.o["reading dqe config from ",string file:hsym file];                                                      /- notify user about reading in config csv
  c:.[0:;((types;enlist",");file);{.lg.e["failed to load dqe configuration file: ",x]}]                         /- read in csv, trap error
 }

gethandles:{exec procname,proctype,w from .servers.SERVERS where (procname in x) | (proctype in x)};

fillprocname:{[rs;h]                                                                                            /- fill procname for results table
  val:rs where not rs in raze a:h`proctype`procname;
  (flip a),val,'`
  }

dupchk:{[idnum;proc]                                                                                            /- checks for unfinished runs that match the new run
  if[count select from .dqe.results where id=idnum,procschk=proc,chkstatus=`started;
    .dqe.updresultstab[idnum;0Np;0b;"error:fail to complete before next run";`failed;proc]];
  }

initstatusupd:{[idnum;funct;params;rs]                                                                          /- set initial values in results table
  .lg.o[`initstatus;"setting up initial record(s) for id ",(string idnum)];
  .dqe.dupchk[idnum]'[rs];                                                                                      /- calls dupchk function to check if last runs chkstatus is still started
  `.dqe.results insert (idnum;funct;`$"," sv string raze (),params;rs[0];rs[1];.z.p;0Np;0b;"";`started);
  }

updresultstab:{[idnum;end;res;des;status;proc]                                                                  /- general function used to update a check in the results table
  c:count select from .dqe.results where id=idnum, procschk=proc,chkstatus=`started;                            /- obtain count of checks that will be updated
  if[c;.lg.o[`updresultstab;raze "run check id ",(string idnum)," update in results table with check status ",string status];
    `.dqe.results set update endtime:end,result:res,descp:enlist des,chkstatus:status from .dqe.results where id=idnum,procschk=proc,chkstatus=`started];
  }

chkcompare:{[idnum;chkcount;comptype;compproc]                                                                  /- function to compare the checks
  if[not chkcount=.dqe.compcounter[idnum][`counter];:()];                                                       /- checks if all async check results have returned
  .lg.o[`chkcompare;"comparison started with id ",string idnum];
  a:.dqe.compcounter[idnum][`results]where not .dqe.compcounter[idnum][`procs]=compproc;                        /- obtain all the check returns
  b:.dqe.compcounter[idnum][`results]where .dqe.compcounter[idnum][`procs]=compproc;                            /- obtain the check to compare the others to
  result:sum comptype\:[a;first b];
  .lg.o[`chkcompare;"comparison finished with id ",string idnum];
 resstring:raze((string compproc)," agrees with ",(first string result),"/",(string .dqe.compcounter[idnum][`counter]-1)," checks");
  .lg.o[`chkcompare;"Updating descp of compare process in the results table"];
  `.dqe.results set update endtime:.z.p,result:1b,descp:enlist resstring,chkstatus:`complete from .dqe.results where id=idnum,chkstatus=`started;
  .dqe.compcounter:idnum _ .dqe.compcounter;
  }

postback:{[idnum;proc;params;result]                                                                            /- function that updates the results table with the check result
  .lg.o[`postback;"postback successful for id ",string idnum];
  if[params`comp;                                                                                               /- if comparision, add to compcounter table
    .dqe.compcounter[idnum]:(
      $[0N=.dqe.compcounter[idnum][`counter];                                                                   /- if counter is null, set it to 1, else add 1 to it
        1;
        1+.dqe.compcounter[idnum][`counter]];
      .dqe.compcounter[idnum][`procs],proc;
      .dqe.compcounter[idnum][`results],last result)];                                                          /- join result to the list

  if["e"=first result;                                                                                          /- checks if error returned from server side
    .dqe.updresultstab[idnum;0Np;0b;result;`failed;proc];
    :()];
  $[params`comp;                                                                                                /- in comparison run, check if all results have returned
    .dqe.chkcompare[idnum;params`compcount;params`comptype;params`compproc];
    .dqe.updresultstab[idnum;.z.p;first result;result[1];`complete;proc]];
  }

getresult:{[funct;params;idnum;proc;hand]
  .lg.o[`getresults;raze"send function over to prcess: ",string proc];
  .async.postback[hand;funct,params`vars;.dqe.postback[idnum;proc;params]];                                     /- send function with variables down handle
  }

runcheck:{[idnum;fn;params;rs]                                                                                  /- function used to send other function to test processes
  .lg.o[`runcheck;"Starting check run ",string idnum];
  fncheck:` vs fn;
  if[not fncheck[2] in key value .Q.dd[`;fncheck 1];                                                            /- run check to make sure passed in function exists
    .lg.e[`runcheck;"Function ",(string fn)," doesn't exist"];
    :()];

  rs:(),rs;                                                                                                     /- set rs to a list
  h:.dqe.gethandles[rs];
  r:.dqe.fillprocname[rs;h];

  compr:`$sv/:[",";string distinct each flip r];
  .lg.o[`runcheck;"Checking if comparison check"];
  $[not params`comp;
    [
    .dqe.initstatusupd[idnum;fn;params]'[r];

    .lg.o[`runcheck;"checking for processes that are not connectable"];
    .dqe.updresultstab[idnum;0Np;0b;"error:can't connect to process";`failed;`];

    procsdown:(h`procname) where 0N = h`w;                                                                      /- checks if any procs didn't get handles
    if[count procsdown;.dqe.updresultstab[idnum;0Np;0b;"error:process is down or has lost its handle";`failed]'[procsdown]];
    ];
    [
    if[(params`compproc) in h`procname;                                                                         /- fail if comparison process is in list of processes to check against
      .lg.e[`runcheck;"Can't compare process with itself"];
      .dqe.updresultstab[idnum;0Np;0b;"error:compare process can't be compared with itself";`failed]'[h`procname];
      :()];

    comph:.dqe.gethandles[params`compproc];                                                                     /- obtain handle for comparison process
    h:h,'comph;

    proccount:count h`procname;
    params,:(enlist `compcount)!enlist proccount;

    .lg.o[`runcheck;(string params`compcount)," procsess will be checked for this comparison"];
    .dqe.initstatusupd[idnum;fn;params;compr];

    if[any[null h`w]|any null r[;1]
      .lg.e[`runcheck;"unable to compare as process down or missing handle"];
      .dqe.updresultstab[idnum;0Np;0b;"error:unable to compare as process down or missing handle";`failed;compr];
      :()];
    ]
   ];
  if[0=count h;.lg.e[`runcheck;"cannot open handle to any given processes"];:()];                             /- check if any handles exist, if not exit function
  .dqe.getresult[value fn;(),params;idnum]'[h[`procname];h[`w]]
  }

results:([]id:`long$();funct:`$();params:`$();procs:`$();procschk:`$();starttime:`timestamp$();endtime:`timestamp$();result:`boolean$();descp:();chkstatus:`$());

loadtimer:{[DICT]
  DICT[`params]: value DICT[`params];                                                                           /- Accounting for potential multiple parameters
  functiontorun:(`.dqe.runcheck;DICT`checkid;.Q.dd[`.dqe;DICT`action];DICT`params;DICT`proc);                   /- function that will be used in timer
  $[DICT[`mode]=`repeat;                                                                                        /- Determine whether the check should be repeated
    .timer.repeat[DICT`starttime;DICT`endtime;DICT`period;functiontorun;"Running check on ",string DICT`proc];
    .timer.once[DICT`starttime;functiontorun;"Running check once on ",string DICT`proc]]
  }

\d .

.servers.CONNECTIONS:`ALL                                                                                       /- set to nothing so that is only connects to discovery

.dqe.init[]

`.dqe.configtable upsert .dqe.readdqeconfig[.dqe.configcsv;"S*SSNNN"]                                           /- Set up configtable from csv
update checkid:til count .dqe.configtable from `.dqe.configtable
update starttime:.z.d+starttime from `.dqe.configtable                                                          /- from timespan to timestamp
update endtime:?[0W=endtime;0Wp;.z.d+endtime] from `.dqe.configtable

/ Sample runcheck:
/ show .dqe.results
/ Load up timers
.dqe.loadtimer '[.dqe.configtable]
