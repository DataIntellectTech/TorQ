// Main consumer process code

// Single update UPD
.consumer.upd.single:{[t;x]
  now:.z.p;
  res:delete sym from $[0h~type x;flip .consumer.singlecols!x;x];
  res:update consumertime:now,feedtotp:time-feedtime,tptoconsumer:now-time,feedtoconsumer:now-feedtime,batching:.consumer.batching,pubmode:`single from res;
  `.consumer.results upsert res;
 };

// Bulk update UPD
.consumer.upd.bulk:{[t;x]
  now:.z.p;
  res:1#select time,feedtime from $[0h~type x;enlist .consumer.bulkcols!first each x;x];
  res:update consumertime:now,feedtotp:time-feedtime,tptoconsumer:now-time,feedtoconsumer:now-feedtime,batching:.consumer.batching,pubmode:`bulk from res;
  `.consumer.results upsert res;
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
  .consumer.tphandle:.servers.gethandlebytype[`segmentedtickerplant`tickerplant;`any];
  .consumer.tphandle @/: {(`.u.sub;x;`)} each `singleupd`bulkupd;
  .consumer.batching:batch;
  `upd set .consumer.upd[mode];
  };