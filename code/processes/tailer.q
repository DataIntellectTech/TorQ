.proc.loadf [getenv[`KDBCODE],"/wdb/common.q"]                                      /-load common wdb parameters & functions

upd:.wdb.replayupd;                                                                 /-start up tailer process, with appropriate upd definition
.wdb.startup[];
upd:.wdb.upd;

if[not .ds.datastripe;.lg.e[`load;"datastriping not enabled"]]                      /-errors out of tailer if datastriping is not turned on

\d .tailer
tailreadertypes:`$"tr_",last "_" vs string .proc.proctype                           /-extract wdb proc segname and append to "tr_"
tailsorttypes:@[value;`tailsorttypes;`tailsort];                                    /-tailsorttypes to make a connection to tailsort process

/- evaluate contents of d dictionary asynchronously
/- flush tailreader handles after timeout
flushtailreload:{
  if[not @[value;`.tailer.tailreloadcomplete;0b];
   @[{neg[x]"";neg[x][]};;()] each key .wdb.d;
   .lg.o[`tail;"tailreload is now complete"];
   .tailer.tailreloadcomplete:1b];
  };

dotailreload:{[pt]
  /-send reload request to tailreaders
  .tailer.tailreloadcomplete:0b;
  .wdb.getprocs[;pt]each .tailer.tailreadertypes;
  if[.wdb.eodwaittime>0;
    .timer.one[.wdb.timeouttime:.proc.cp[]+.wdb.eodwaittime;(value;".tailer.flushtailreload[]");"release all tailreaders as timer has expired";0b];
  ];
  };

\d .wdb

hdbsettings[`taildir]:getenv`KDBTAIL
.ds.lasttimestamp:.z.p-.ds.periodstokeep*.ds.period

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

/- eod - send end of day message to main tailsort process
endofday:{[pt;processdata]
  .lg.o[`eod;"end of day message received - ",spt:string pt];
  /- call datastripeendofday
  .wdb.datastripeendofday[pt;processdata];
  /- find handle to send message to tailsort process
  ts:exec w from .servers.getservers[`proctype;.tailer.tailsorttypes;()!();1b;0b];
  /- if no tailsort process connected, do eod sort from tailer & exit early
  if[0=count ts;
    .lg.e[`connection;"no connection to the ",(string .tailer.tailsorttypes)," could be established, failed to send end of day message"];:()];
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
