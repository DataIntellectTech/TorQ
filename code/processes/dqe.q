\d .dqe

configcsv:@[value;`.dqe.configcsv;first .proc.getconfigfile["dqeconfig.csv"]];

init:{
  .lg.o[`init;"searching for servers"];
  .servers.startup[];                                                                                           /- Open connection to discovery
  }

configtable:([] action:`symbol$(); params:(); proctype:(); procname:(); mode:(); starttime:`timestamp$(); endtime:`timestamp$(); period:`timespan$())

readdqeconfig:{[file]
  .lg.o["reading dqe config from ",string file:hsym file];                                                      /- notify user about reading in config csv
  c:.[0:;(("S****NNN";enlist",");file);{.lg.e["failed to load dqe configuration file: ",x]}]                    /- read in csv, trap error
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

initstatusupd:{[id;funct;vars;rs]                                                                               /- set initial values in results table
  .lg.o[`initstatus;"setting up initial record(s) for id ",(string id)];
  `.dqe.results insert (id;funct;`$"," sv string raze (),vars;rs[0];rs[1];.z.p;0Np;0b;"";`started);
  }

failchk:{[idnum;error;proc]
  c:count select from .dqe.results where id=idnum, procschk=proc;
  .lg.o[`failerr;raze "run check id ",(string idnum)," update in results table with a fail, with ",(string error)];
  `.dqe.results set update chkstatus:`failed,output:0b,descp:c#enlist error from .dqe.results where id=idnum, procschk=proc;
  }

postback:{[idnum;proc;result]
  $["e"=first result;
  .dqe.failchk[idnum;result;proc];
  `.dqe.results set update endtime:.z.p,output:`boolean$ string first result,descp:enlist last result,chkstatus:`complete from .dqe.results where id=idnum,procschk=proc];
  }

getresult:{[funct;vars;id;proc;hand]
  .lg.o[`getresults;raze"send function over to prcess: ",string proc];
  .async.postback[hand;funct,vars;.dqe.postback[id;proc]];                                                      /- send function with variables down handle
  }

runcheck:{[id;fn;vars;rs]                                                                                       /- function used to send other function to test processes
  fncheck:` vs fn;
  if[not fncheck[2] in key value .Q.dd[`;fncheck 1];                                                            /- run check to make sure passed in function exists
    .lg.e[`runcheck;"Function ",(string fn)," doesn't exist"];
    :()];

  rs:(),rs;                                                                                                     /- set rs to a list
  h:.dqe.gethandles[rs];                                                                                        /- check if processes exist and are valid

  r:.dqe.fillprocname[rs;h];
  .dqe.initstatusupd[id;fn;vars]'[r];
  
  .dqe.failchk[id;"error:can't connect to process";`];
  procsdown:(h`procname) where 0N = h`w;
  .dqe.failchk[id;"error:process is down or has lost its handle"]'[procsdown];

  if[0=count h;.lg.e[`handle;"cannot open handle to any given processes"];:()];                                 /- check if any handles exist, if not exit function
  ans:.dqe.getresult[value fn;(),vars;id]'[h[`procname];h[`w]]
  }

results:([]id:`long$();funct:`$();vars:`$();procs:`$();procschk:`$();starttime:`timestamp$();endtime:`timestamp$();output:`boolean$();descp:();chkstatus:`$());

\d .

.servers.CONNECTIONS:`ALL                                                                                       /- set to nothing so that is only connects to discovery

.dqe.init[]

`.dqe.configtable upsert .dqe.readdqeconfig[.dqe.configcsv]                                                     /- Set up configtable from csv
update checkid:til count .dqe.configtable from `.dqe.configtable

/Sample runcheck:
/.dqe.runcheck[first .dqe.configtable[`checkid];` sv (`.dqe; first .dqe.configtable[`action]);`quote;`rdb]
/show .dqe.results

/timer for first commit - subjected to changed
.timer.repeat[first .dqe.configtable[`starttime];first .dqe.configtable[`endtime];first .dqe.configtable[`period];(`.dqe.runcheck[first .dqe.configtable[`checkid];` sv (`.dqe;first .dqe.configtable[`action]);first .dqe.configtable[`params]];`);"running check ",string first .dqe.configtable[`action]," on ",string first .dqe.configtable[`proctype]];
