// Main script for the feeder process

// Define publisher functions

// appends timestamp when feed is called and when consumer upd is called
// use: feedtimetp each til 1000000
feedsingletp:{
  curtime:.z.p;
  (neg h)(`.u.upd;`timing0;(`a;curtime));(neg h)(::)
 };

feedsinglestp:{
  curtime:.z.p;
  (neg h)(`.u.upd;`timing1;(`a;curtime));(neg h)(::)
 };

// appends timestamp when feed is called and when consumer upd is called
// fills with dummy trade data to test sending through 100k message one at a time
// use: feeddatatp each til 10
feedbulktp:{
  curtime:.z.p;
  (neg h)(`.u.upd;`timingdata0;flip (flip t[maxn]),'curtime);(neg h)(::)
 };

feedbulkstp:{
  curtime:.z.p;
  (neg h)(`.u.upd;`timingdata1;flip (flip t[maxn]),'curtime);(neg h)(::)
 };

// Run publisher function in a loop for 1 minute
.feed.run:{
  // run pub function in a while loop
  };

// Process init function - to be triggered from Observer
.feed.init:{
  .proc.loadf first (.Q.opt .z.x)[`config];
  .servers.startup[];
  // get handles to observer and (S)TP
  };