\d .dqe

queries:`tablecount`nullcheck`anomcheck;
resultstab:2!flip (`procs`tab,queries)!((`$();`$()),count[queries]#`long$());

init:{
  .lg.o[`init;"searching for servers"];
  .servers.startup[];                                                                                           /- Open connection to discovery
  }

updresultstab:{[proc;col;table;tabinput]
  .lg.o[`updresultstab;"Updating results table for ",(string table)," table from proc ",string proc];
  ![table;enlist ((=;procs;proc);(=;tab;table));0b;(enlist col)!enlist tabinput]                                /- Update query results into table
  }

chkinresults:{[proc;table]
  if[not (proc;table) in key resultstab;
    .lg.o[`chkinresults;"adding null row for ",(string table)," table from proc ",string proc];
    resultstab insert (proc;table,(count cols resultstab -2)#0N);]
  }

qpostback:{[proc;params;query;result]
  .lg.o[`qpostback;"Postback sucessful for ",string proc];
  tab:key result;
  .dqe.chkinresults[proc]'[tab];
  .dqe.updresultstab[proc;query]'[tab;value result];
  }

runquery:{[query;params;rs]
  .lg.o[`runquery;"Starting query run for ",string query];
  if[1<count rs;.lg.e[`runquery"error: can only send query to one remote service, trying to send to ",string count rs];:()];
  if[not rs in exec procname from .servers.SERVERS;.lg.e[`runquery;"error: remote service must be a proctype";:()]];

  h:.dqe.gethandles[(),rs];
  .async.postback[h`w;((value query),params);.dqe.qpostback[h`procname;query]];
  }

tablecountstore:{[partition]
  .Q.pt!{count ?[x;enliist(=;.Q.pf;partition);0b;()]}[partition]'[.Q.pt]
  }

\d .

.servers.CONNECTIONS:`ALL                                                                                       /- set to nothing so that is only connects to discovery

.dqe.init[]
