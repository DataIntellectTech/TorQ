\d .wdb
.proc.loadf [getenv[`KDBCODE],"/processes/wdb.q"]
hdbsettings[`taildir]:getenv`KDBTAIL
.ds.lasttimestamp:.z.p-.ds.periodstokeep*.ds.period

if[not .ds.datastripe;.lg.e[`load;"datastiping not enabled"]]                       /-errors out of tailer if datastriping is not turned on

\d .tailer
tailreadertypes:`$"tr_",last "_" vs string .proc.proctype                           /-extract wdb proc segname and append to "tr_"
eodtypes:@[value;`eodtypes;`eodprocess];                                            /-eodtypes to make a connection to EOD process

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
.servers.register[.servers.procstab;.tailer.eodtypes;1b]

\d .

/- eod - send end of day message to main EOD process
endofday:{[pt;processdata]
    .lg.o[`eod;"end of day message received - ",spt:string pt];

    /- trigger final save down from tailer
    endofdaysave[processdata];

    /- find handle to send message to eod process
    eodp:exec w from .servers.getservers[`proctype;.tailer.eodtypes;()!();1b;0b];

    /- exit early if no eod process connected
    if[0=count eodp;.lg.e[`connection;"no connection to the ",(string .tailer.eodtypes)," could be established, failed to send end of day message"];:()];

    /- send procname to eod process so it loads correct TDB
    procname:.proc.procname;
    neg[first eodp](`endofday;pt;procname);
    .lg.o[`eod;"end of day message sent to eod process"];
    };

endofdaysave:{[processdata]
  /- function to flush remaining in-memory data to disk when end of day message is received
  .lg.o[`save;"saving the ",(", " sv string tl:.wdb.tablelist[],())," table(s) to disk"];
  currp:first exec distinct end from .ds.access where end<>0N;
  .wdb.datastripeendofperiod[currp;.z.p;processdata];
  .lg.o[`savefinish;"finished saving remaining data to disk"];
  };

/- add endofday to tailer namespace and overwrite .wdb.endofday function
.tailer.endofday:.wdb.endofday:endofday;

/- initialise datastripe
.lg.o[`dsinit;"initialising datastripe"];
initdatastripe[];


/- create HDB sym file and taildir symlink
.ds.symlink[];
