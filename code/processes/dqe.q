\d .dqe

init:{
  .lg.o[`init;"searching for servers"];
  .servers.startup[];                                                                                           /- Open connection to discovery
  }

tableexists:{x in tables[]};                                                                                    /- function to check for table, param is table name as a symbol

runcheck:{[fn;vars;rs]                                                                                          /- function used to send other function to test processes
  discov:.servers.querydiscovery`ALL;
  if[0<count s:{
      $[1<count sf:x in raze exec procname,proctype from y;x where 0=sf;(enlist x) where 0=enlist sf]           /- check if processes exist and are valid, slight diff check if atom or list input
    }[rs;discov];
    .lg.e[`process;(-1_(raze/) string s,\:",")," processes are not connectable"]];
  h:.servers.opencon each exec hpup from discov where (procname in rs)|(proctype in rs);                        /- check discovery and open handles to other processes using procname and/or proctype
  if[0=count h;.lg.e[`handle;"cannot open handle to any given processes"];:()];                                 /- check if any handles exist, if not exit function
  ans:{[func;vrs;hand]hand(func;vrs)}[fn;vars]'[h];                                                             /- send function with variables down handle
  hclose each h;                                                                                                /- close handles as they are no longer needed
  ans
  }

\d .

.servers.CONNECTIONS:`;                                                                                         /- set to nothing so that is only connects to discovery

.dqe.init[]
