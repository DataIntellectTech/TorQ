\d .dqe

configcsv:@[value;`.dqe.configcsv;first .proc.getconfigfile["dqengineconfig.csv"]];

readdqeconfig:{[file;types]
  .lg.o["reading dqengine config from ",string file:hsym file];                                                     /- notify user about reading in config csv
  c:.[0:;((types;enlist",");file);{.lg.e["failed to load dqe configuration file: ",x]}]                        /- read in csv, trap error

 }

init:{
  .lg.o[`init;"searching for servers"];
  .servers.startup[];                                                                                           /- Open connection to discovery
  }

qpostback:{[proc;params;result]

  }

runquery:{[query;params;rs]
  .lg.o[`runquery;"Starting query run for ",string query];
  if[1<count rs;.lg.e[`runquery"error: can only send query to one remote service, trying to send to ",string count rs];:()];
  if[not rs in exec procname from .servers.SERVERS;.lg.e[`runquery;"error: remote service must be a proctype";:()]];

  h:.dqe.gethandles[(),rs];
  r:.dqe.fillprocname[(),rs;h];
  .async.postback[exec x from r;query,params;.dqe.qpostback[proc;params]];
  }

loadtimer:{[d]
  d[`proc]:value raze d[`proc];
  .timer.once[d`starttime;({x+4};1);("Running check on ",string d[`proc])]
  }

configtimer:{[]
  t:.dqe.readdqeconfig[.dqe.configcsv;"***NN"];  
  t:update starttime:.z.d+starttime from t;
  d:t[0];
  .dqe.loadtimer[d]
  / {.dqe.loadtimer[x]}each t
  }


\d .

.servers.CONNECTIONS:`ALL                                                                                       /- set to nothing so that is only connects to discovery

.dqe.init[]
/.dqe.configtimer[] 
