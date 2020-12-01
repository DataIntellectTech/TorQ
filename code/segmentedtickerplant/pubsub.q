// Get pubsub common code
.proc.loadf[getenv[`KDBCODE],"/common/pubsub.q"];

// Define UPD and ZTS wrapper functions

// Check for end of day/period and call inner UPD function
.stpps.upd.def:{[t;x]
  if[.stplg.nextendUTC<now:.z.p;.stplg.checkends now];
  // Type check allows update messages to contain multiple tables/data
  $[0h<type t;.stplg.updmsg'[t;x;now+.eodtime.dailyadj];.stplg.updmsg[t;x;now+.eodtime.dailyadj]];
  .stplg.seqnum+:1;
 };

// Don't check for period/day end if process is chained STP
.stpps.upd.chained:{[t;x]
  now:.z.p;
  $[0h<type t;.stplg.updmsg'[t;x;now+.eodtime.dailyadj];.stplg.updmsg[t;x;now+.eodtime.dailyadj]];
  .stplg.seqnum+:1;
 };

// Call inner ZTS function and check for end of day/period
.stpps.zts.def:{
  .stplg.ts now:.z.p;
  .stplg.checkends now
 };

// Don't check for period/day end if process is chained STP
.stpps.zts.chained:{
  .stplg.ts now:.z.p
 };