\d .dqe

configcsv:@[value;`.dqe.configcsv;first .proc.getconfigfile["dqeconfig.csv"]];

init:{
  .lg.o[`init;"searching for servers"];
  .servers.startup[];                                                                                           /- Open connection to discovery
  }

configtable:(


  action:`symbol$();              // type of check

  params:();                     // specific parameters to pass

  proctype:();                   // process type

  procesname:();                 // process name

  mode:();                       // single run or repeat

  starttime:`timespan$();        // when to start the check

  endtime:`timespan$(); 
         
  period: `timespan$())         // periodicity of runs

readdqeconfig:{[file]
  // read in config CSV
  .lg.o["reading dqe config from ",string file:hsym file];
  // read in csv file, trap error
  c:.[0:;(("S****NNN";enlist",");file);{.lg.e["failed to load dqe configuration file: ",x]}]
  `configtable upsert c;
 }

gethandles:{exec procname,proctype,w from .servers.SERVERS where (procname in x) | (proctype in x)};

tableexists:{x in tables[]};                                                                                    /- function to check for table, param is table name as a symbol

runcheck:{[fn;vars;rs]                                                                                          /- function used to send other function to test processes
  fncheck:` vs fn;
  if [not fncheck[2] in key value .Q.dd[`;fncheck 1];                                                           /- run check to make sure passed in function exists
    .lg.e[`function;"Function ",(string fn)," doesn't exist"];
    :()];

  rs:(),rs;                                                                                                     /- set rs to a list
  h:.dqe.gethandles[rs];                                                                                        /- check if processes exist and are valid
  
  missingproc:rs where not rs in raze h`procname`proctype;                                                      /- check all process exist
  if[0<count missingproc;.lg.e[`process;(", "sv string missingproc)," processes are not connectable"]];

  if[0=count h;.lg.e[`handle;"cannot open handle to any given processes"];:()];                                 /- check if any handles exist, if not exit function
  ans:{[funct;vars;hand].async.postback[hand;(funct;vars);`.dqe.showresult]}[value fn;vars]'[h[`w]]             /- send function with variables down handle
  }

showresult:{show x};

\d .

.servers.CONNECTIONS:`ALL                                                                                       /- set to nothing so that is only connects to discovery

.dqe.init[]
