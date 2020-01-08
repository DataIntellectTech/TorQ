\d .dqe

configcsv:@[value;`.dqe.configcsv;first .proc.getconfigfile["dqeconfig.csv"]];
detailcsv:@[value;`.dqe.detailcsv;first .proc.getconfigfile["dqedetailtab.csv"]];

compcounter:([id:`long$()]counter:`long$();procs:();results:());

init:{
  .lg.o[`init;"searching for servers"];
  .servers.startup[];                                                                                           /- Open connection to discovery
  .api.add .'value each .dqe.readdqeconfig[.dqe.detailcsv;"SB***"];                                             /- add dqe functions to .api.detail
  }

configtable:([] action:`$(); params:(); proctype:`$(); procname:`$(); mode:`$(); starttime:`timespan$(); endtime:`timespan$(); period:`timespan$())

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

initstatusupd:{[idnum;funct;vars;rs]                                                                            /- set initial values in results table
  .lg.o[`initstatus;"setting up initial record(s) for id ",(string idnum)];
  .dqe.dupchk[idnum]'[rs];                                                                                      /- calls dupchk function to check if last runs chkstatus is still started
  `.dqe.results insert (idnum;funct;`$"," sv string raze (),vars;rs[0];rs[1];.z.p;0Np;0b;"";`started);
  }

updresultstab:{[idnum;end;res;des;status;proc]                                                                  /- general function used to update a check in the results table
  c:count select from .dqe.results where id=idnum, procschk=proc,chkstatus=`started;                            /- obtain count of checks that will be updated
  if[c;.lg.o[`updresultstab;raze "run check id ",(string idnum)," update in results table with check status ",string status];
    `.dqe.results set update endtime:end,result:res,descp:enlist des,chkstatus:status from .dqe.results where id=idnum,procschk=proc,chkstatus=`started];
  }

chkcompare:{[idnum;chkcount;comptype;compproc]                                                                  /- function to compare the checks
  if[not chkcount=.dqe.compcounter[idnum][`counter];:()];                                                       /- checks if all async check results have returned
  a:.dqe.compcounter[idnum][`results]where not .dqe.compcounter[idnum][`procs]=compproc;                        /- obtain all the check returns
  b:.dqe.compcounter[idnum][`results]where .dqe.compcounter[idnum][`procs]=compproc;                            /- obtain the check to compare the others to
  result:sum comptype[a;first b];
  resstring:raze((first string result)," other checks agree. This result is ",string b);
  `.dqe.results set update descp:enlist resstring from .dqe.results where id=idnum,procschk=compproc;
  .dqe.compcounter:idnum _ .dqe.compcounter;
  }

postback:{[idnum;proc;compare;result]                                                                           /- function that updates the results table with the check result
  if[compare[0];                                                                                                /- if comparision, add to compcounter table
    .dqe.compcounter[idnum]:(
      $[0N=.dqe.compcounter[idnum][`counter];                                                                   /- if counter is null, set it to 1, else add 1 to it
        1;
        1+.dqe.compcounter[idnum][`counter]];
      .dqe.compcounter[idnum][`procs],proc;
      .dqe.compcounter[idnum][`results],last result)];                                                          /- join result to the list

  if["e"=first result;                                                                                          /- checks if error returned from server side
    .dqe.updresultstab[idnum;0Np;0b;result;`failed;proc];
    :()];

  .dqe.updresultstab[idnum;.z.p;first result;result[1];`complete;proc];
  if[compare[0];                                                                                                /- in comparison run, check if all results have returned
    .dqe.chkcompare[idnum;compare[3];compare[1];compare[2]]];
  }

getresult:{[funct;vars;idnum;compare;proc;hand]
  .lg.o[`getresults;raze"send function over to prcess: ",string proc];
  .async.postback[hand;funct,vars;.dqe.postback[idnum;proc;compare]];                                           /- send function with variables down handle
  }

runsetup:{[idnum;fn;vars;rs]
  fncheck:` vs fn;
  if[not fncheck[2] in key value .Q.dd[`;fncheck 1];                                                            /- run check to make sure passed in function exists
    .lg.e[`runcheck;"Function ",(string fn)," doesn't exist"];
    :()];

  h:.dqe.gethandles[rs]                                                                                         /- check if processes exist and are valid
  }

runcheck:{[idnum;fn;vars;rs]                                                                                    /- function used to send other function to test processes
  rs:(),rs;                                                                                                     /- set rs to a list
  h:.dqe.runsetup[idnum;fn;vars;rs];

  r:.dqe.fillprocname[rs;h];
  .dqe.initstatusupd[idnum;fn;vars]'[r];

  .dqe.updresultstab[idnum;0Np;0b;"error:can't connect to process";`failed;`];
  procsdown:(h`procname) where 0N = h`w;                                                                        /- checks if any procs didn't get handles
  if[count procsdown;.dqe.updresultstab[idnum;0Np;0b;"error:process is down or has lost its handle";`failed]'[procsdown]];

  if[0=count h;.lg.e[`handle;"cannot open handle to any given processes"];:()];                                 /- check if any handles exist, if not exit function
  .dqe.getresult[value fn;(),vars;idnum;(),0b]'[h`procname;h`w]
  }

runcomparison:{[idnum;fn;vars;rs;comptype]                                                                      /- ran for comparison checks between multiple processes
  compproc:rs[0];
  rs:1_(),rs;                                                                                                   /- set rs to a list
  h:.dqe.runsetup[idnum;fn;vars;rs];

  if[compproc in h`procname;                                                                                    /- fail if comparison process is in list of processes to check against
    .dqe.updresultstab[idnum;0Np;0b;"error:compare process can't be compared with itself";`failed]'[h`procname];
    :()];

  comph:.dqe.gethandles[compproc];                                                                              /- obtain handle for comparison process
  h:h,'comph;
  proccount:count h`procname;

  r:.dqe.fillprocname[rs;h];
  compr:.dqe.fillprocname[rs;comph];
  compr:first compr where all not `=compr;
  .dqe.initstatusupd[idnum;fn;vars;compr];

  if[any[null h`w]|any null r[;1]
    .dqe.updresultstab[idnum;0Np;0b;"error:unable to compare as process down or missing handle";`failed;0b]'[h`procname];
    :()];

  if[0=count h;.lg.e[`handle;"cannot open handle to any given processes"];:()];                                 /- check if any handles exist, if not exit function

  .dqe.getresult[value fn;(),vars;idnum;(1b;comptype;compproc;proccount)]'[h[`procname];h[`w]]
  }

results:([]id:`long$();funct:`$();vars:`$();procs:`$();procschk:`$();starttime:`timestamp$();endtime:`timestamp$();result:`boolean$();descp:();chkstatus:`$());

loadtimer:{[DICT]
  DICT[`params]: value DICT[`params];                                                                           /- Accounting for potential multiple parameters
  functiontorun:(`.dqe.runcheck;DICT`checkid;.Q.dd[`.dqe;DICT`action];DICT`params;DICT`procname);               /- function that will be used in timer
  $[DICT[`mode]=`repeat;                                                                                        /- Determine whether the check should be repeated
    .timer.repeat[DICT`starttime;DICT`endtime;DICT`period;functiontorun;"Running check on ",string DICT`proctype];
    .timer.once[DICT`starttime;functiontorun;"Running check once on ",string DICT`proctype]]
  }

\d .

.servers.CONNECTIONS:`ALL                                                                                       /- set to nothing so that is only connects to discovery

.dqe.init[]

`.dqe.configtable upsert .dqe.readdqeconfig[.dqe.configcsv;"S*SSSNNN"]                                          /- Set up configtable from csv
update checkid:til count .dqe.configtable from `.dqe.configtable
update starttime:.z.d+starttime from `.dqe.configtable                                                          /- from timespan to timestamp
update endtime:?[0W=endtime;0Wp;.z.d+endtime] from `.dqe.configtable

/ Sample runcheck:
/ show .dqe.results
/ Load up timers
.dqe.loadtimer '[.dqe.configtable]
