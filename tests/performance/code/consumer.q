// Main consumer process code

// Main UPD for all updates
upd:{[t;x]
  now:.z.p;
  res:raze (::;.consumer.getfirstrows) @' ?[x;;0b;()] each enlist each .consumer.whereclause;
  res:select time,feedtime,batching:batch,pubmode:mode from res;
  res:update consumertime:now,feedtotp:time-feedtime,tptoconsumer:now-time,feedtoconsumer:now-feedtime from res;
  `.consumer.results upsert `batching`pubmode xcols res;
 };

// Get first row from each update (.consumer.bulkrows gets set from the Observer)
.consumer.getfirstrows:{
  x .consumer.bulkrows*til 1|(count x) div .consumer.bulkrows
 };

// Clear results table
.consumer.cleartable:{
  .lg.o[`clear;"Clearing local results table..."];
  delete from `.consumer.results;
 };

// Set up connection management, subscribe to tables and choose the UPD function
.consumer.init:{[mode;batch]
  .proc.loadf first (.Q.opt .z.x)[`config];
  .servers.startup[];
  tptype:$[batch like "vanilla*";`tickerplant;
           batch like "tick*";`tick;
           `segmentedtickerplant
   ];
  .consumer.tphandle:.servers.gethandlebytype[tptype;`any];
  .consumer.tphandle(`.u.sub;`updates;`);
  };