\d .dqe

init:{
  .lg.o[`init;"searching for servers"];
  .servers.startup[];                                                                                           /- Open connection to discovery
  }

gethandles:{exec procname,proctype,w from .servers.SERVERS where (procname in x) | (proctype in x)};

tableexists:{x in tables[]};                                                                                    /- function to check for table, param is table name as a symbol

runcheck:{[id;fn;vars;rs]                                                                                       /- function used to send other function to test processes
  fncheck:` vs fn;
  if [not fncheck[2] in key value .Q.dd[`;fncheck 1];                                                           /- run check to make sure passed in function exists
    .lg.e[`function;"Function ",(string fn)," doesn't exist"];
    :()];

  {[tab;id;funct;vars;rs] tab insert (id;funct;`$"," sv string (),vars;rs;.z.p;0Np;`;`started)}[`.dqe.results;id;fn;vars]'[rs];
  rs:(),rs;                                                                                                     /- set rs to a list
  h:.dqe.gethandles[rs];                                                                                        /- check if processes exist and are valid

  missingproc:rs where not rs in raze h`procname`proctype;                                                      /- check all process exist
  if[0<count missingproc;.lg.e[`process;(", "sv string missingproc)," processes are not connectable"]];
  {[tab;idnum;proc]update status:`failed from tab where id=idnum, procs=proc}[`.dqe.results;id]'[missingproc];

  if[0=count h;.lg.e[`handle;"cannot open handle to any given processes"];:()];                                 /- check if any handles exist, if not exit function
  ans:{[funct;vars;hand].async.postback[hand;(funct;vars);`.dqe.showresult]}[value fn;vars]'[h[`w]]             /- send function with variables down handle
  }

showresult:{show x,'.z.p};

results:([]id:`long$();funct:`$();vars:`$();procs:`$();starttime:`timestamp$();endtime:`timestamp$();output:`$();status:`$());

\d .

.servers.CONNECTIONS:`ALL                                                                                       /- set to nothing so that is only connects to discovery

.dqe.init[]
