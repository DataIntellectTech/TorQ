\d .dqe

init:{
  .lg.o[`init;"searching for servers"];
  .servers.startup[];                                                                                           /- Open connection to discovery
  }

gethandles:{exec procname,proctype,w from .servers.SERVERS where (procname in x) | (proctype in x)};

tableexists:{[tabs]                                                                                             /- function to check for table, param is table name as a symbol
  result:();
  $[1=all a:tabs in tables[];result:(1b;"all tables exist");result:(0b;raze ("," sv string tabs where not a)," missing from process")]
  };

runcheck:{[id;fn;vars;rs]                                                                                       /- function used to send other function to test processes
  fncheck:` vs fn;
  if [not fncheck[2] in key value .Q.dd[`;fncheck 1];                                                           /- run check to make sure passed in function exists
    .lg.e[`function;"Function ",(string fn)," doesn't exist"];
    :()];
  
  rs:(),rs;                                                                                                     /- set rs to a list
  h:.dqe.gethandles[rs];                                                                                        /- check if processes exist and are valid
  
  {[h;rs]                                                                                                       /- fill procname for results table
    $[0=first where rs in ' h`procname`proctype;
      rs;
      1=first where rs in ' h`procname`proctype;
      first exec procname from flip h where proctype=`rdb;`]}[h]'[rs];
  
  {[id;funct;vars;rs;procname]                                                                                  /- set initial values in results table
    `.dqe.results insert (id;funct;`$"," sv string (),vars;rs;procname;.z.p;0Np;`;"";`started)}[id;fn;vars]'[rs;r];
  
  missingproc:rs where not rs in raze h`procname`proctype;                                                      /- check all process exist
  if[0<count missingproc;.lg.e[`process;(", "sv string missingproc)," processes are not connectable"]];
  {[tab;idnum;proc]update chkstatus:`failed,descp:enlist "error:can't connect to process" from tab where id=idnum, procs=proc}[`.dqe.results;id]'[missingproc];
  
  if[0=count h;.lg.e[`handle;"cannot open handle to any given processes"];:()];                                 /- check if any handles exist, if not exit function
  ans:{[funct;vars;id;proc;hand]
    .async.postback[hand;(funct;vars);`.dqe.postback[id;proc]]}[value fn;vars;id]'[h[`procname];h[`w]]          /- send function with variables down handle
  }


postback:{[idnum;proc;result]
  update endtime:.z.p,output:`$ string first result,descp:enlist last result,chkstatus:`complete from `.dqe.results where id=idnum,procschk=proc;
  }

results:([]id:`long$();funct:`$();vars:`$();procs:`$();procschk:`$();starttime:`timestamp$();endtime:`timestamp$();output:`$();descp:();chkstatus:`$());

\d .

.servers.CONNECTIONS:`ALL                                                                                       /- set to nothing so that is only connects to discovery

.dqe.init[]
