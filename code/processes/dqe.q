\d .dqe

configcsv:@[value;`.dqe.configcsv;first .proc.getconfigfile["dqeconfig.csv"]];

init:{
  .lg.o[`init;"searching for servers"];
  .servers.startup[];                                                                                           /- Open connection to discovery
  }

configtable:([] action:`$(); params:(); proctype:`$(); procname:`$(); mode:`$(); starttime:`timestamp$(); endtime:`timestamp$(); period:`timespan$())

readdqeconfig:{[file]
  .lg.o["reading dqe config from ",string file:hsym file];                                                      /- notify user about reading in config csv
  c:.[0:;(("S*SSSPPN";enlist",");file);{.lg.e["failed to load dqe configuration file: ",x]}]                    /- read in csv, trap error
 }

gethandles:{exec procname,proctype,w from .servers.SERVERS where (procname in x) | (proctype in x)};

constructcheck:{[construct;chktype]                                                                             /- function to check for table,variable,function or view
  chkfunct:{system x," ",string $[null y;`;y]};
  dict:`table`variable`view`function!chkfunct@/:"avbf";
  .lg.o[`dqe;"checking if ", (s:string construct)," ",(s2:string chktype), " exists"];
  $[construct in dict[chktype][];
    (1b;s," ",s2," exists");
    (0b;s," ",s2," missing from process")]
  }

tableticking:{[tab;timeperiod;timetype]                                                                         /- [table to check;time window to check for records;`minute or `second]
  $[0<a:count select from tab where time within (.z.p-timetype$"J"$string timeperiod;.z.p);
    (1b;"there are ",(string a)," records");
    (0b;"the table is not ticking")]
  }

chkslowsub:{[threshold]                                                                                         /- function to check for slow subscribers
  .lg.o[`dqe;"Checking for slow subscribers"];
  overlimit:(key .z.W) where threshold<sum each value .z.W;
  $[0=count overlimit;
    (1b;"no data queues over the limit, in ",string .proc.procname);
    (0b;raze"handle(s) ",("," sv string overlimit)," have queues")]
  }

fillprocname:{[rs;h]                                                                                            /- fill procname for results table
  val:rs where not rs in raze a:h`proctype`procname;
  (flip a),val,'`
  }

dupchk:{[idnum;proc]                                                                                            /- checks for unfinished runs that match the new run
  if[count select from .dqe.results where id=idnum,procschk=proc,chkstatus=`started;
    .dqe.failchk[idnum;"error:fail to complete before next run";proc]];
  }

initstatusupd:{[idnum;funct;vars;rs]                                                                            /- set initial values in results table
  .lg.o[`initstatus;"setting up initial record(s) for id ",(string idnum)];
  .dqe.dupchk[idnum]'[rs];                                                                                      /- calls dupchk function to check if last runs chkstatus is still started
  `.dqe.results insert (idnum;funct;`$"," sv string raze (),vars;rs[0];rs[1];.z.p;0Np;0b;"";`started;`no);
  }

failchk:{[idnum;error;proc]                                                                                     /- general fail function, used to fail a check with inputted error message
  c:count select from .dqe.results where id=idnum, procschk=proc,chkstatus=`started;
  if[c;.lg.o[`failerr;raze "run check id ",(string idnum)," update in results table with a fail, with ",(string error)]];
  `.dqe.results set update chkstatus:`failed,output:0b,descp:c#enlist error,manual:`no from .dqe.results where id=idnum, procschk=proc,chkstatus=`started;
  }

postback:{[idnum;proc;result]                                                                                   /- function that updates the results table with the check result
  $["e"=first result;                                                                                           /- checks if error returned from server side
  .dqe.failchk[idnum;result;proc];
  `.dqe.results set update endtime:.z.p,output:first result,descp:enlist last result,chkstatus:`complete,manual:`no from .dqe.results where id=idnum,procschk=proc,chkstatus=`started];
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

results:([]id:`long$();funct:`$();vars:`$();procs:`$();procschk:`$();starttime:`timestamp$();endtime:`timestamp$();output:`boolean$();descp:();chkstatus:`$();manual:`$());

loadtimer:{[DICT]
  DICT[`params]: value DICT[`params];                                                                           /- Accounting for potential multiple parameters
  functiontorun:(`.dqe.runcheck;DICT`checkid;.Q.dd[`.dqe;DICT`action];DICT`params;DICT`procname);               /- function that will be used in timer
  $[DICT[`mode]=`repeat;                                                                                        /- Determine whether the check should be repeated
    .timer.repeat[DICT`starttime;DICT`endtime;DICT`period;functiontorun;"Running check on ",string DICT`proctype];
    .timer.once[DICT`starttime;functiontorun;"Running check once on ",string DICT`proctype]]
  }

reruncheck:{[chkid]
  d:exec action, params, procname from .dqe.configtable where checkid=chkid;
  d[`params]: value d[`params][0];                                                                          
  .dqe.runcheck[chkid;.Q.dd[`.dqe;d`action];d`params;d`procname];  
  }

/getallresults:{[manualchecks] 
/  t:.dqe.results;
/  t:update manual:(count t)#`no from t;
/  .dqe.runcheck[chkid;.Q.dd[`.dqe;d`action];d`params;d`procname];
/  t[manualchecks;`manual]:`yes;
/  t
/  }

\d .

.servers.CONNECTIONS:`ALL                                                                                       /- set to nothing so that is only connects to discovery

.dqe.init[]

`.dqe.configtable upsert .dqe.readdqeconfig[.dqe.configcsv]                                                     /- Set up configtable from csv
update checkid:til count .dqe.configtable from `.dqe.configtable

/ Sample runcheck:
/ show .dqe.results
/ Load up timers
.dqe.loadtimer '[.dqe.configtable]

/manualchecks:()
/chkid:3
/.dqe.reruncheck[chkid]
/manualchecks,:last select where id=chkid from .dqe.results
/.dqe.getallresults[manualchecks]
