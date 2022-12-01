us:@[value;`us;([]querytime:`timestamp$();id:`long$();timer:`long$();zcmd:`symbol$();proctype:`symbol$();procname:`symbol$;status:`char$();a:`int$();u:`symbol$();w:`int$();cmd:();mem:();sz:`long$();error:())];

upd:{[t;x] if [t in `.usage.usage; `us insert x]};

.servers.startup[];
start_sub:{[subprocs]
  hds:(),exec w from .servers.SERVERS where proctype in subprocs;
  {
   .lg.o[`startsub;"subscribing to ", string first exec procname from .servers.SERVERS where w=x];
   x(`.u.sub;`.usage.usage;`);
   .lg.o[`completesub;"subscribed"];

  }each hds;
 };
start_sub[subprocs];

readlog:{[file]

        // Remove leading backtick from symbol columns, convert a and w columns back to integers
        update zcmd:`$1 _' string zcmd, procname:`$1 _' string procname, proctype:`$1 _' string proctype, u:`$1 _' string u,
                a:"I"$-1 _' a, w:"I"$-1 _' w from
        // Read in file
        @[{update "J"$'" " vs' mem from flip (cols `.queries.us)!("PJJSSSC*S***JS";"|")0:x};hsym`$file;{'"failed to read log file : ",x}]};

queryfeed:{
 h(".u.upd";`usage;value flip select from us);
 us::0#us;
 };

flushreload:{
 .lg.o[`flushreload1;"fr1"];
 procnames:exec distinct procname from .servers.SERVERS where proctype in subprocs;
  {h(".u.upd";`usage;value flip select from readlog[raze string (getenv `KDBLOG),"/usage_",(raze x),"_",.z.d,".log"])} each string each procnames;
 };

.servers.startupdepcycles[`qtp;10;0W];
h:.servers.gethandlebytype[`qtp;`any];

.timer.once[.proc.cp[]+0D00:00:10.000;(`flushreload;`);"Flush reload"]
.timer.repeat[.proc.cp[];0Wp;0D00:00:00.200;(`queryfeed;`);"Publish Query Feed"];
