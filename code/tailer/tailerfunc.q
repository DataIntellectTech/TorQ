trtype:`$"tr_",last "_" vs string .proc.proctype                           /-extract wdb proc segname and append to "tr_"
tailreadertypes:trtype

/- evaluate contents of d dictionary asynchronously
/- flush tailreader handles after timeout
flushtailreload:{
  if[not @[value;`.wdb.tailreloadcomplete;0b];
   @[{neg[x]"";neg[x][]};;()] each key d;
   .lg.o[`tail;"tailreload is now complete"];
   .wdb.tailreloadcomplete:1b];
  };

dotailreload:{[pt]
  /-send reload request to tailreaders
  .wdb.tailreloadcomplete:0b;
  getprocs[;pt].wdb.tailreadertypes;
  if[eodwaittime>0;
    .timer.one[.wdb.timeouttime:.proc.cp[]+.wdb.eodwaittime;(value;".wdb.flushtailreload[]");"release all tailreaders as timer has expired";0b];
  ];
  };

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
