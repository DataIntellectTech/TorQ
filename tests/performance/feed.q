// Main script for the feeder process

// Send a single message
.feed.pub.single:{
  .feed.asyncpubhandle(`.u.upd;`singleupd;(`sym;.z.p))[::];
 };

// Send multiple messages
.feed.pub.bulk:{
  .feed.asyncpubhandle(`.u.upd;`bulkupd;.feed.bulk,enlist .feed.bulkrows#.z.p)[::];
 };

// Run publisher function in a loop for 1 minute & signal to Observer when done
.feed.run:{
  now:.z.p;
  while[.z.p<now+.feed.looptime;.feed.publish[]];
  .feed.observerhandle(`.observer.runcomplete);
  };

// Process init function - triggered from Observer
.feed.init:{[mode]
  .proc.loadf first (.Q.opt .z.x)[`config];
  .servers.startup[];
  .feed.asyncpubhandle:neg .servers.gethandlebytype[`segmentedtickerplant`tickerplant;`any];
  .feed.observerhandle:.servers.gethandlebytype[`observer;`any];
  .feed.publish:.feed.pub[mode];
  };