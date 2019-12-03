\d .dqe

init:{
  .lg.o[`init;"searching for servers"];
  .servers.startup[];                                                                                           /- Open connection to discovery
  }

gethandles:{exec procname,proctype,w from .servers.SERVERS where (procname in x) | (proctype in x)};

tableexists:{[tab]                                                                                              /- function to check for table, param is table name as a symbol
  result:();
  .lg.o[`dqe;"checking if ", (string tab), " table exists"];
  $[1=a:tab in tables[];result:(1b;((string tab)," table exists"));result:(0b;(string tab)," missing from process")]
  };

tableticking:{[tab;timeperiod;timetype]                                                                         /- function to check if table is increasing in size
  $[0<a:count select from tab where time within (.z.p-timetype$"J"$string timeperiod;.z.p);                     /- params are tab        - table to check
    (1;"there are ",(string a)," records");                                                                     /-            timeperiod - time back to check for records
    (0b;"the table is not ticking")]                                                                            /-            timetype   - either `minute or `second
  }

fillprocname:{[h;rs]                                                                                            /- fill procname for results table
  $[0=first where rs in ' h`procname`proctype;
    enlist rs,'rs;
    1=first where rs in ' h`procname`proctype;
    rs,'exec procname from flip h where proctype=rs;enlist rs,'`]
  }

initstatusupd:{[id;funct;vars;rs]                                                                               /- set initial values in results table
  .lg.o[`initstatus;"setting up initial record(s) for id ",(string id)];
  `.dqe.results insert (id;funct;`$"," sv string (),vars;rs[0];rs[1];.z.p;0Np;`;"";`started);
  }

failunconnected:{[idnum;proc]
  .lg.o[`failuncon;raze "run check id ",(string idnum)," update in results table with a fail as can't connect"];
  `.dqe.results set update chkstatus:`failed,descp:enlist "error:can't connect to process" from .dqe.results where id=idnum, procs=proc;
  }

failerror:{[idnum;proc;error]
 .lg.o[`failerr;raze "run check id ",(string idnum)," update in results table with a fail, with ",(string error)];
 `.dqe.results set update chkstatus:`failed,descp:enlist error from .dqe.results where id=idnum, procschk=proc;
 }

postback:{[idnum;proc;result]
  $["e"=first result;
  .dqe.failerror[idnum;proc;result];
  `.dqe.results set update endtime:.z.p,output:`$ string first result,descp:enlist last result,chkstatus:`complete from .dqe.results where id=idnum,procschk=proc];
  }

getresult:{[funct;vars;id;proc;hand]
  .lg.o[`getresults;raze"send function over to prcess: ",(string proc)];
  .async.postback[hand;funct,vars;.dqe.postback[id;proc]];                                                      /- send function with variables down handle
  }

runcheck:{[id;fn;vars;rs]                                                                                       /- function used to send other function to test processes
  fncheck:` vs fn;
  if [not fncheck[2] in key value .Q.dd[`;fncheck 1];                                                           /- run check to make sure passed in function exists
    .lg.e[`runcheck;"Function ",(string fn)," doesn't exist"];
    :()];

  rs:(),rs;                                                                                                     /- set rs to a list
  h:.dqe.gethandles[rs];                                                                                        /- check if processes exist and are valid

  r:raze .dqe.fillprocname[h]'[rs];
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

