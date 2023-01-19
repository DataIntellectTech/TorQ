.proc.loadf [getenv[`KDBCODE],"/wdb/common.q"]                             /-load common wdb parameters & functions
\d .ts

taildir:hsym `$getenv`KDBTAIL;                                             /-load in taildir env variables
hdbdir:hsym `$getenv`KDBHDB;                                               /-load in hdb env variables
rdbtypes:@[value;`rdbtypes;.wdb.rdbtypes];                                 /- rdbs to send reset window message to
taildbs:key taildir;                                                       /-list of tailDBs that need saved to HDB
taildirs:();                                                               /-empty list to append tailDB paths to - to be used
savelist:@[value;`savelist;`quote`trade];                                  /-list of tables to save to HDB
reloadorder:@[value;`reloadorder;`hdb`rdb];
eodwaittime:@[value;`eodwaittime;0D00:00:10.000];                          /-length of time to wait for async callbacks to complete at eod
date:.z.d;

.servers.CONNECTIONS:(distinct .servers.CONNECTIONS,.servers.tailsorttypes,.servers.hdbtypes,.servers.rdbtypes);
.servers.startup[];

\d .
/-status table that keeps track of tailsorts and table being saved
status:([] process:`symbol$(); status: ;table:());
/-savelist table that keeps track of any tables needing saving                                                
savelisttab:([segment:`int$()] savelist:`symbol$(); tablelist:);
/-list containing all tailsort workers from each segment 
workerlist:();  

tailermsg:{[procname]
  /-function that's triggered by tailer(s) at endofday
  .lg.o[`endofday;"endofday message received from ", string[procname]];
  seg:last string procname;
  workerlist::(distinct workerlist, exec procname from .servers.getservers[`proctype;.servers.tailsorttypes;()!();1b;0b]);
  workers:workerlist where seg={(string x)8} each workerlist;
  savelist:`$"savelistseg",seg;
  /-upsert both tailsortworkers to status table 
  `status upsert {(x;-1;`)} each workers;
  .lg.o[`tailsortconns;"segment ",string[seg]," has the following tailsorts available ", .Q.s1[workers]];
  /-upsert the related segment savelist tables
  `savelisttab upsert ("I"$seg;savelist;.ts.savelist);
  .lg.o[`tablelist;"segment ",string[seg]," has table savelist of ", .Q.s1[.ts.savelist]]
  /-both tailsort workers are available for savedown
  update status:1 from `status where process in workers;
  {distributetable[x]} each workers;
 };

availabletailsort:{
 /-buffer function to delegate any available tailsorts for more savedown
 processes:exec process where status=1 from status;
 if[count string[processes]<>0; .lg.o[`availability;.Q.s1[processes], " are available for table savedown"]];
 /-call distribute using any tailsort processes that are available
 {distributetable[x]} each processes;
 };

distributetable:{[processname]
 /-load balance any tables ready to be merged to HDB via tailsort(s)
 seg:"I"$(string processname)8;
 segname:`$"savelistseg",string[seg];
 tailerproc:`$"tailer",string[seg];
 ts:exec w from .servers.getservers[`proctype;.servers.tailsorttypes;()!();1b;0b] where procname=processname;
 /-table list that keeps track on any tables currently being saved 
 tablist:exec distinct table from status;
 .lg.o[`distribute;"now preparing ",string[processname]," with current tables being saved ",.Q.s1[raze tablist]];
 /-extract all the tables needing saving for the corresponding segment
 savelist:first exec tablelist from savelisttab where segment=seg; 
 /-select the first available table
 tabname:first savelist except tablist; 
 .lg.o[`distribute;"assinging ",.Q.s1[tabname]," to ",string[processname]," for savedown"]; 
 update table:tabname from `status where process=processname;
 /-update the savelisttab  
 `savelisttab upsert (seg;segname;savelist except tabname);
 .lg.o[`distribute;"updating segment ",string[seg]," savelist to ",.Q.s1[raze savelist except tabname]];
 /-join the new table to the ones being saved
 tablist,:tabname; 
 /-if there is a table ready to be saved, notify the corresponding tailsort
 if[(count string[tabname])<>0; neg[first ts](`endofday;.ts.date;tailerproc;.proc.procname;tabname);
  /-set the tailsort process to busy
  update status:0 from `status where process=processname;
  ];
 };

notify:{[procname;proctype]
 /-function that tailsort(s) will trigger to notify centraltailsort that a table has been saved
 seg:first string[procname]8;
 workers:workerlist where seg={(string x)8} each workerlist;
 tab:first exec table from status where process=procname;
 .lg.o[`notify;"table ",string[tab]," from ",string[procname]," now complete "];
 update status:1 from `status where process=procname;
 update table:` from `status where process=procname;
 /-log any tables yet to be saved
 if[0<>(count raze exec tablelist from savelisttab where segment="I"$seg)+
  (sum count each string exec table from status where process in workers);
   .lg.o[`notify;"tables from segment ",string[seg]," still remaining to save"];
  ];
 /-call endofday if all tables for a segment is saved and no tables are currently being saved
 if[0=(count raze exec tablelist from savelisttab where segment="I"$seg)+
  (sum count each string exec table from status where process in workers);
   /-turn off all the tailsort processes 
   update status:neg 1 from `status where process in workers;
   .lg.o[`notify;"all tables saved from segment - ",string[seg]];
   /-call end of day function
   endofday[.ts.date];
   /-call the tailsort reload function
   tailsortreload[workers];
   .ts.date+:1;
  ];
  /-call availabletailsort for any edge cases 
  availabletailsort[]; 
 };

tailsortreload:{[tailsortprocname]
 /-function to execute the tailreader eod reload on the primary tailsort
 mainworker:first tailsortprocname;
 seg:first string[mainworker]8;
 tailerproc:`$"tailer",seg;
 /-get the main tailsort handle for the segment
 ts:exec w from .servers.getservers[`proctype;.servers.tailsorttypes;()!();1b;0b] where procname=mainworker;
 neg[first ts](`endofdayreload;.ts.date;.proc.procname;tailerproc);
 };
                                                       
addpattr:{[hdbdir;pt;tabname]
  /-load column to add p attribute on
  pcol:.ds.loadtablekeycols[][tabname];
  /-add p attr to on-disk table
  .lg.o[`attr;"adding p attribute to the ",string[pcol]," col in ",string[tabname]];
  addattr:{[hdbdir;pt;tabname;pcol]
    @[.Q.par[hdbdir;pt;tabname];pcol;`p#]
  };
  .[addattr;
    (hdbdir;pt;tabname;pcol);
    {[e] .lg.e[`attr;"Failed to add attr : ",e]}
  ];
  };

resetrdbwindow:{
  /-function to notify rdb when tailsort process complete
  .lg.o[`rdbwindow;"resetting rdb moving time window"];
  rdbprocs:.servers.getservers[`proctype;.ts.rdbtypes;()!();1b;0b];
  {neg[x]".rdb.tailsortcomplete:1b"}each exec w from rdbprocs;
  };

savecomplete:{[pt;tablelist]
  /-function to add p attr to HDB tables, delete tailDBs
  addpattr[.ts.hdbdir;pt;] each tablelist;
  tailmsg::0;
  .ts.taildirs:();
  resetrdbwindow[];
  getprocs[;pt] each .ts.reloadorder;
  .lg.o[`endofday;"end of day save complete"]
  {@[`.;x;0#]}each .wdb.tablelist[];
  };

/-function to send reload message to rdbs/hdbs
reloadproc:{[h;d;ptype]
 countreload:count[raze .servers.getservers[`proctype;;()!();1b;0b]each .ts.reloadorder];
 $[.ts.eodwaittime>0;
  {[x;y;ptype].[{neg[y]@x};(x;y);
  {[ptype;x].lg.e[`reloadproc;"failed to reload the ",string[ptype]];'x}[ptype]]}[({@[`. `reload;x;()]; 
  (neg .z.w)(`.wdb.handler;1b); (neg .z.w)[]};d);h;ptype];
  @[h;(`reload;d);{[ptype;e] .lg.e[`reloadproc;"failed to reload the ",string[ptype],".  The error was : ",e]}[ptype]]
 ];
 .lg.o[`reload;"the ",string[ptype]," has been successfully reloaded"];
 }

/-function to discover rdbs/hdbs and attempt to reconnect
getprocs:{[x;y]
 a:exec (w!x) from .servers.getservers[`proctype;x;()!();1b;0b];
 /-exit if no valid handle
 if[0=count a; .lg.e[`connection;"no connection to the ",(string x)," could be established... failed to reload ",string x];:()];
 .lg.o[`connection;"connection to the ", (string x)," has been located"];
 /-send message along each handle a
 reloadproc[;y;value a] each key a;
 }

endofday:{[pt]
  /-function to trigger data load & save to HDB once endofday message is received from tailer(s)
  tailsortcount:count exec w from .servers.getservers[`proctype;.servers.tailsorttypes;()!();1b;0b];
  .lg.o[`endofday;"end of day message received "," - ",string[pt]];
  /-check if all tailers that are online have completed their endofday savedown
  if[(tailsortcount=count(::)@\:?[status;enlist (=;`status;-1);0b;(enlist`process)!enlist`process]); savecomplete[pt;.ts.savelist]];
  };
  