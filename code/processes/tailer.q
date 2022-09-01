\d .wdb
.proc.loadf [getenv[`KDBCODE],"/processes/wdb.q"]
hdbsettings[`taildir]:getenv`KDBTAIL
.ds.lasttimestamp:.z.p-.ds.periodstokeep*.ds.period

if[not .ds.datastripe;.lg.e[`load;"datastiping not enabled"]]                       /-errors out of tailer if datastriping is not turned on

\d .tailer
tailreadertypes:`$"tr_",last "_" vs string .proc.proctype                           /-extract wdb proc segname and append to "tr_"
tailsorttypes:@[value;`tailsorttypes;`tailsort];                                    /-tailsorttypes to make a connection to tailsort process

/- evaluate contents of d dictionary asynchronously
/- flush tailreader handles after timeout
flushtailreload:{
  if[not @[value;`.tailer.tailreloadcomplete;0b];
   @[{neg[x]"";neg[x][]};;()] each key d;
   .lg.o[`tail;"tailreload is now complete"];
   .tailer.tailreloadcomplete:1b];
  };

dotailreload:{[pt]
  /-send reload request to tailreaders
  .tailer.tailreloadcomplete:0b;
  .wdb.getprocs[;pt].tailer.tailreadertypes;
  if[.wdb.eodwaittime>0;
    .timer.one[.wdb.timeouttime:.proc.cp[]+.wdb.eodwaittime;(value;".tailer.flushtailreload[]");"release all tailreaders as timer has expired";0b];
  ];
  };

\d .wdb
reloadproc:{[h;d;ptype;reloadlist]
        .wdb.countreload:count[raze .servers.getservers[`proctype;;()!();1b;0b] each reloadlist];
        $[eodwaittime>0;
                {[x;y;ptype].[{neg[y]@x};(x;y);{[ptype;x].lg.e[`reloadproc;"failed to reload the ",string[ptype]];'x}[ptype]]}[({@[`. `reload;x;()]; (neg .z.w)(`.wdb.handler;1b); (neg .z.w)[]};d);h;ptype];
                @[h;(`reload;d);{[ptype;e] .lg.e[`reloadproc;"failed to reload the ",string[ptype],".  The error was : ",e]}[ptype]]
        ];
        .lg.o[`reload;"the ",string[ptype]," has been successfully reloaded"];
        }

getprocs:{[x;y]
        a:exec (w!x) from .servers.getservers[`proctype;x;()!();1b;0b];
        /-exit if no valid handle
        if[0=count a; .lg.e[`connection;"no connection to the ",(string x)," could be established... failed to reload ",string x];:()];
        .lg.o[`connection;"connection to the ", (string x)," has been located"];
        /-send message along each handle a
        reloadproc[;y;value a;x] each key a;
        }

.servers.register[.servers.procstab;.tailer.tailreadertypes;1b]
.servers.register[.servers.procstab;.tailer.tailsorttypes;1b]

\d .

endofdaysort:{[pt]
  /- function to be called when no tailsort process can be connected, to carry out eod sort from tailer
  .lg.o[`eodsort;"attempting to complete eod sort from tailer"];
  /- get tailsort code
  .proc.loadf [getenv[`KDBCODE],"/processes/tailsort.q"];
  /- sleep allows for multiple tailers to save to HDB at different times uninterrupted
  .os.sleep[`$first .proc.params[`segid]];
  /- merge tables from sym partitions & save to HDB
  dir:` sv .ds.td,.proc.procname,`$string pt;
  mergebypart[dir;pt;;.wdb.hdbdir] each .ts.savelist;
  /- add p attr to on-disk HDB tables
  addpattr[.wdb.hdbdir;pt;] each .ts.savelist;
  /- delete intraday data from tailDB
  deletetaildb[dir];
  .lg.o[`eodsort;"end of day sort complete for ",string[.proc.procname]];
  };

/- eod - send end of day message to main tailsort process
endofday:{[pt;processdata]
  .lg.o[`eod;"end of day message received - ",spt:string pt];
  /- call datastripeendofday
  .wdb.datastripeendofday[pt;processdata];
  /- find handle to send message to tailsort process
  ts:exec w from .servers.getservers[`proctype;.tailer.tailsorttypes;()!();1b;0b];
  /- if no tailsort process connected, do eod sort from tailer & exit early
  if[0=count ts;
    .lg.e[`connection;"no connection to the ",(string .tailer.tailsorttypes)," could be established, failed to send end of day message"];
    endofdaysort[pt];
    :()
  ];
  /- send procname to tailsort process so it loads correct tailDB
  neg[first ts](`endofday;pt;.proc.procname);
  .lg.o[`eod;"end of day message sent to tailsort process"];
  };

/- add endofday to tailer namespace and overwrite .wdb.endofday function
.tailer.endofday:.wdb.endofday:endofday;

/- initialise datastripe
.lg.o[`dsinit;"initialising datastripe"];
initdatastripe[];


/- create HDB sym file and taildir symlink
.ds.symlink[];
