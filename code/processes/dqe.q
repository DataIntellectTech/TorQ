\d .dqe

init:{
  .lg.o[`init;"searching for servers"];
  .servers.startup[];                                                                                           /- Open connection to discovery
  }

tableexists:{x in tables[]};                                                                                    /- function to check for table, param is table name as a symbol

runcheck:{[fn;vars;rs]                                                                                          /- function used to send other function to test processes
  rs:(),rs;                                                                                                     /- set rs to a list
  h:exec w from .servers.SERVERS where (procname in rs) | (proctype in rs);                                     /- check if processes exist and are valid
  if[0=count h;.lg.e[`handle;"cannot open handle to any given processes"];:()];                                 /- check if any handles exist, if not exit function
  ans:{[func;vrs;hand]hand(func;vrs)}[fn;vars]'[h];                                                             /- send function with variables down handle
  ans
  }

\d .

.servers.CONNECTIONS:`ALL                                                                                       /- set to nothing so that is only connects to discovery

.dqe.init[]
