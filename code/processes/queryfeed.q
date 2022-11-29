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

queryfeed:{
 h(".u.upd";`usage;value flip select from us);
 us::0#us;
 };

.servers.startupdepcycles[`qtp;10;0W];
h:.servers.gethandlebytype[`qtp;`any];

.timer.repeat[.proc.cp[];0Wp;0D00:00:00.200;(`queryfeed;`);"Publish Query Feed"];
