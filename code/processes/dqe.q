\d .dqe

configcsv:@[value;`.dqe.configcsv;first .proc.getconfigfile["dqeconfig.csv"]];

init:{
  .lg.o[`init;"searching for servers"];
  .servers.startup[];                                                                                           /- Open connection to discovery
  }

configtable:([] action:`symbol$(); params:(); proctype:(); procname:(); mode:(); starttime:`timespan$(); endtime:`timespan$(); period:`timespan$())

readdqeconfig:{[file]
  .lg.o["reading dqe config from ",string file:hsym file];                                                      /- notify user about reading in config csv
  c:.[0:;(("S****NNN";enlist",");file);{.lg.e["failed to load dqe configuration file: ",x]}]                    /- read in csv, trap error
 }

gethandles:{exec procname,proctype,w from .servers.SERVERS where (procname in x) | (proctype in x)};

tableexists:{[tab]                                                                                              /- function to check for table, param is table name as a symbol
  .lg.o[`dqe;"checking if ", (s:string tab), " table exists"];
  $[1=tab in tables[];
    (1b;s," table exists");
    (0b;s," missing from process")]
  };

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
  `.dqe.results insert (id;funct;`$"," sv string raze (),vars;rs[0];rs[1];.z.p;0Np;`;"";`started);
  }

failunconnected:{[idnum;proc]
  .lg.o[`failuncon;raze "run check id ",(string idnum)," update in results table with a fail as can't connect"];
  `.dqe.results set update chkstatus:`failed,output:`0,descp:enlist "error:can't connect to process" from .dqe.results where id=idnum, procs=proc;
  }

failerror:{[idnum;proc;error]
 .lg.o[`failerr;raze "run check id ",(string idnum)," update in results table with a fail, with ",(string error)];
 `.dqe.results set update chkstatus:`failed,output:`0,descp:enlist error from .dqe.results where id=idnum, procschk=proc;
 }

postback:{[idnum;proc;result]
  $["e"=first result;
  .dqe.failerror[idnum;proc;result];
  `.dqe.results set update endtime:.z.p,output:`$ string first result,descp:enlist last result,chkstatus:`complete from .dqe.results where id=idnum,procschk=proc];
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
  
  missingproc:rs where not rs in raze h`procname`proctype;                                                      /- check all process exist
  if[0<count missingproc;.lg.e[`runcheck;(", "sv string missingproc)," process(es) are not connectable"]];
  .dqe.failunconnected[id]'[missingproc];

  if[0=count h;.lg.e[`handle;"cannot open handle to any given processes"];:()];                                 /- check if any handles exist, if not exit function
  ans:.dqe.getresult[value fn;(),vars;id]'[h[`procname];h[`w]]
  }

results:([]id:`long$();funct:`$();vars:`$();procs:`$();procschk:`$();starttime:`timestamp$();endtime:`timestamp$();output:`$();descp:();chkstatus:`$());

\d .

.servers.CONNECTIONS:`ALL                                                                                       /- set to nothing so that is only connects to discovery

.dqe.init[]

`.dqe.configtable upsert .dqe.readdqeconfig[.dqe.configcsv]                                                     /- Set up configtable from csv
update checkid:til count .dqe.configtable from `.dqe.configtable

/Sample runcheck:
/.dqe.runcheck[first .dqe.configtable[`checkid];` sv (`.dqe; first .dqe.configtable[`action]);`quote;`rdb]
/show .dqe.results

/timer for first commit - subjected to changed
.timer.repeat[first .dqe.configtable[`starttime];first .dqe.configtable[`endttime];.dqe.runcheck[` sv (`.dqe; first .dqe.configtable[`action]);first .dqe.configtable[`params];first .dqe.configtable[`proctype];(`runnow;`);"running the tableexists check"]


