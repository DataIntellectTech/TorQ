// Main script for the feed process

// Send a single message
.feed.pub.single:{
  .feed.asyncpubhandle(`.u.upd;`updates;.feed.singleupd,enlist 1#.z.p);
  .feed.asyncpubhandle(::);
 };

// Send multiple messages
.feed.pub.bulk:{
  .feed.asyncpubhandle(`.u.upd;`updates;.feed.bulkupd,enlist .feed.bulkrows#.z.p);
  .feed.asyncpubhandle(::);
 };

// Run publisher function in a loop & signal to Observer when done
.feed.run:{
  .lg.o[`run;"Start of run"];
  start:.z.p;
  while[.z.p<start + .feed.looptime;.feed.publish[]];
  .feed.asyncobserverhandle:neg .servers.gethandlebytype[`observer;`any];
  .feed.asyncobserverhandle(`.observer.runcomplete;::);
  };

// Set up connections, connect to TP/STP depending on batch type and set the publish function
.feed.init:{[mode;batch]
  .proc.loadf first (.Q.opt .z.x)[`config];
  .servers.startup[];
  tptype:$[batch like "vanilla*";`tickerplant;
           batch like "tick*";`tick;
           `segmentedtickerplant
   ];
  .feed.asyncpubhandle:neg .servers.gethandlebytype[tptype;`any];
  .feed.publish:.feed.pub[mode];
  .feed.batchmode:batch,mode;
  .feed.bulkupd:.feed.bulk,flip 2 cut (2*.feed.bulkrows)#.feed.batchmode;
  .feed.singleupd:flip enlist first each .feed.bulkupd;
  };