\d .dqe

configcsv:@[value;`.dqe.configcsv;first .proc.getconfigfile["dqeconfig.csv"]];
dqedbdir:@[value;`dqedbdir;`:dqedb];
detailcsv:@[value;`.dqe.detailcsv;first .proc.getconfigfile["dqedetailtab.csv"]];
gmttime:@[value;`gmttime;1b];
partitiontype:@[value;`partitiontype;`date];
getpartition:@[value;`getpartition;
	{{@[value;`.dqe.currentpartition;
		(`date^partitiontype)$(.z.D,.z.d)gmttime]}}];                                                   /-function to determine the partition value
detailcsv:@[value;`.dqe.detailcsv;first .proc.getconfigfile["dqedetail.csv"]];

testing:@[value;`.dqe.testing;0b];                                                                              /- testing varible for unit tests

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
  if[`=proc;:()];
  if[count select from .dqe.results where id=idnum,procschk=proc,chkstatus=`started;
    .dqe.failchk[idnum;"error:fail to complete before next run";proc]];
  }

initstatusupd:{[idnum;funct;vars;rs]                                                                            /- set initial values in results table
  .lg.o[`initstatus;"setting up initial record(s) for id ",(string idnum)];
  .dqe.dupchk[idnum]'[rs];                                                                                      /- calls dupchk function to check if last runs chkstatus is still started
  `.dqe.results insert (idnum;funct;`$"," sv string raze (),vars;rs[0];rs[1];.z.p;0Np;0b;"";`started);
  }

failchk:{[idnum;error;proc]                                                                                     /- general fail function, used to fail a check with inputted error message
  c:count select from .dqe.results where id=idnum, procschk=proc,chkstatus=`started;
  if[c;.lg.o[`failerr;raze "run check id ",(string idnum)," update in results table with a fail, with ",(string error)]];
  `.dqe.results set update chkstatus:`failed,output:0b,descp:c#enlist error from .dqe.results where id=idnum, procschk=proc,chkstatus=`started;
  }

postback:{[idnum;proc;result]                                                                                   /- function that updates the results table with the check result
  $["e"=first result;                                                                                           /- checks if error returned from server side
  .dqe.failchk[idnum;result;proc];
  `.dqe.results set update endtime:.z.p,output:first result,descp:enlist last result,chkstatus:`complete from .dqe.results where id=idnum,procschk=proc,chkstatus=`started];
  }

getresult:{[funct;vars;idnum;proc;hand]
  .lg.o[`getresults;raze"send function over to prcess: ",string proc];
  .async.postback[hand;funct,vars;.dqe.postback[idnum;proc]];                                                   /- send function with variables down handle
  }

runcheck:{[idnum;fn;vars;rs]                                                                                    /- function used to send other function to test processes
  fncheck:` vs fn;
  if[not fncheck[2] in key value .Q.dd[`;fncheck 1];                                                            /- run check to make sure passed in function exists
    .lg.e[`runcheck;"Function ",(string fn)," doesn't exist"];
    :()];

  rs:(),rs;                                                                                                     /- set rs to a list
  h:.dqe.gethandles[rs];                                                                                        /- check if processes exist and are valid

  r:.dqe.fillprocname[rs;h];
  .dqe.initstatusupd[idnum;fn;vars]'[r];
  
  .dqe.failchk[idnum;"error:can't connect to process";`];
  procsdown:(h`procname) where 0N = h`w;                                                                        /- checks if any procs didn't get handles
  if[count procsdown;.dqe.failchk[idnum;"error:process is down or has lost its handle"]'[procsdown]];

  if[0=count h;.lg.e[`handle;"cannot open handle to any given processes"];:()];                                 /- check if any handles exist, if not exit function
  ans:.dqe.getresult[value fn;(),vars;idnum]'[h[`procname];h[`w]]
  }

results:([]id:`long$();funct:`$();vars:`$();procs:`$();procschk:`$();starttime:`timestamp$();endtime:`timestamp$();output:`boolean$();descp:();chkstatus:`$());

loadtimer:{[DICT]
  DICT[`params]: value DICT[`params];                                                                           /- Accounting for potential multiple parameters
  functiontorun:(`.dqe.runcheck;DICT`checkid;.Q.dd[`.dqe;DICT`action];DICT`params;DICT`procname);               /- function that will be used in timer
  $[DICT[`mode]=`repeat;                                                                                        /- Determine whether the check should be repeated
    .timer.repeat[DICT`starttime;DICT`endtime;DICT`period;functiontorun;"Running check on ",string DICT`proctype];
    .timer.once[DICT`starttime;functiontorun;"Running check once on ",string DICT`proctype]]
  }

\d .

.dqe.currentpartition:.dqe.getpartition[];                                                                      /- initialize current partition

.servers.CONNECTIONS:`ALL                                                                                       /- set to nothing so that is only connects to discovery

.u.end:{[pt]    /- setting up .u.end for dqe
  .dqe.endofday[.dqe.getpartition[]];
  .dqe.currentpartition:pt+1;
  };

.dqe.init[]

`.dqe.configtable upsert .dqe.readdqeconfig[.dqe.configcsv;"S*SSSNNN"]                                          /- Set up configtable from csv
update checkid:til count .dqe.configtable from `.dqe.configtable
update starttime:.z.d+starttime from `.dqe.configtable                                                          /- from timespan to timestamp
update endtime:?[0W=endtime;0Wp;.z.d+endtime] from `.dqe.configtable

/ Sample runcheck:
/ show .dqe.results
/ Load up timers
if[not .dqe.testing;.dqe.loadtimer '[.dqe.configtable]]
