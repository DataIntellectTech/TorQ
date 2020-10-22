// Main script for the feeder process

// Send a single message
.feed.pub.single:{
  .feed.asyncpubhandle(`.u.upd;`singleupd;(`sym;.z.p));
  .feed.asyncpubhandle(::);
 };

// Send multiple messages
.feed.pub.bulk:{
  .feed.asyncpubhandle(`.u.upd;`bulkupd;.feed.bulk,enlist .feed.bulkrows#.z.p);
  .feed.asyncpubhandle(::);
 };

// Run publisher function in a loop for 1 minute & signal to Observer when done
.feed.run:{
  .lg.o[`run;"Start of run"];
  now:.z.p;
  while[.z.p<now + .feed.looptime;.feed.publish[]];
  .lg.o[`run;"End of run"];
  .feed.asyncobserverhandle:neg .servers.gethandlebytype[`observer;`any];
  .feed.asyncobserverhandle(`.observer.runcomplete;::);
  };

// Process init function - triggered from Observer
.feed.init:{[mode]
  .proc.loadf first (.Q.opt .z.x)[`config];
  .servers.startup[];
  .feed.asyncpubhandle:neg .servers.gethandlebytype[`segmentedtickerplant`tickerplant;`any];
  .feed.publish:.feed.pub[mode];
  };