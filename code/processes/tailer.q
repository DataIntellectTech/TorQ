.proc.loadf [getenv[`KDBCODE],"/wdb/common.q"]                                      /-load common wdb parameters & functions

upd:.wdb.upd;


.tailer.tailreadertypes:`$"tr_",last "_" vs string .proc.proctype                           /-extract wdb proc segname and append to "tr_"
.tailer.tailsorttypes:@[value;`tailsorttypes;`tailsort];                                    /-tailsorttypes to make a connection to tailsort process
.servers.CONNECTIONS:(distinct .servers.CONNECTIONS,.wdb.hdbtypes,.wdb.rdbtypes,.wdb.gatewaytypes,.wdb.tickerplanttypes,.wdb.sorttypes,.wdb.sortworkertypes,.tailer.tailreadertypes,.tailer.tailsorttypes) except `
.servers.startup[];

/- evaluate contents of d dictionary asynchronously
/- flush tailreader handles after timeout
.tailer.flushtailreload:{
  if[not @[value;`.tailer.tailreloadcomplete;0b];
   @[{neg[x]"";neg[x][]};;()] each key .wdb.d;
   .lg.o[`tail;"tailreload is now complete"];
   .tailer.tailreloadcomplete:1b];
  };

.tailer.replayupd:{[f;t;d]
  /- execute the supplied function
  f[t;d];
  /- if the data count is greater than the threshold, then flush data to disk
  if[(rpc:count[value t]) > lmt:.wdb.maxrows[t];
    .lg.o[`replayupd;"row limit (",string[lmt],") exceeded for ",string[t],". Table count is : ",string[rpc],". Flushing table to disk..."];
    /- if datastriping is on then filter before savedown to the tailDB, if not save down to wdbhdb
    .ds.applyfilters[enlist t;.sub.filterdict];
    .ds.savealltables[.ds.td] each .wdb.tablelist[]
  ];
  }[upd];

.tailer.dotailreload:{[pt]
  /-send reload request to tailreaders
  .tailer.tailreloadcomplete:0b;
  .wdb.getprocs[;pt]each .tailer.tailreadertypes;
  if[.wdb.eodwaittime>0;
    .timer.one[.wdb.timeouttime:.proc.cp[]+.wdb.eodwaittime;(value;".tailer.flushtailreload[]");"release all tailreaders as timer has expired";0b];
  ];
  };

/ - if there is data in the tailDB directory for the partition remove it before replay
/ - is only run during datastriping mode
.tailer.cleartaildir:{
  if[() ~ key ` sv(.ds.td;.proc.procname;`$string .wdb.currentpartition);
    .lg.o[`deletewdbdata;"no directory found at ",1_string ` sv(.ds.td;.proc.procname;`$string .wdb.currentpartition)];
    :();
  ];
  .lg.o[`deletetaildb;"removing taildb (",(delstrg:1_string ` sv(.ds.td;.proc.procname;`$string .wdb.currentpartition)),") prior to log replay"];
  @[.os.deldir;delstrg;{[e] .lg.e[`deletewdbdata;"Failed to delete existing taildir data.  Error was : ",e];'e }];
  .lg.o[`deletewdbdata;"finished removing taildb data prior to log replay"];
 };

upd:.tailer.replayupd;                                                                 /-start up tailer process, with appropriate upd definition
.tailer.cleartaildir[];
.wdb.startup[];
upd:.wdb.upd;

if[not .ds.datastripe;.lg.e[`load;"datastriping not enabled"]]                      /-errors out of tailer if datastriping is not turned on

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
