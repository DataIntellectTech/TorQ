// Main consumer process code

// 1. Evaluate data schema
// 2. Re-write UPDs to deal with updated data schemas (no global references!!!)
// 3. Have init function triggered from Observer?

// UPD functions for different testing modes

// Single message insert for old TP
.consumer.upd.singleTP:{
  curtime:.z.p;
  `timingtp insert delete sym from update consumertime:curtime, feedtotp:time-feedtime, tptoconsumer:curtime-time, feedtoconsumer:curtime-feedtime from y;
 };

// Expects single list to insert into table
.consumer.upd.singleSTP:{
  curtime:.z.p;
  if[(value `..tpmode) in `timingstpdefaultbatch`defaultbatcherr`timingstpautobatch`autobatcherr;
    `timingstp insert delete sym from update consumertime:curtime, feedtotp:time-feedtime, tptoconsumer:curtime-time, feedtoconsumer:curtime-feedtime from y;];
  if[(value `..tpmode) in `timingstpimm`immerr;
    stptime:y[0];feedtime:y[2]; 
    `timingstp insert stptime,feedtime,curtime,(stptime-feedtime),(curtime-stptime),(curtime-feedtime);];
 };

// upd functions to test multiple entries of dummy data for each message
.consumer.upd.bulkTP:{
  curtime:.z.p;
  `timingdatatp insert 1#select time,feedtime,consumertime,feedtotp,tptoconsumer,feedtoconsumer from 
    update consumertime:curtime,feedtotp:time-feedtime,tptoconsumer:curtime-time,feedtoconsumer:curtime-feedtime from y;
 };

// timestamp is same for each message, keep only one
.consumer.upd.bulkSTP:{
  curtime:.z.p;
  if[(value `..tpmode) in `timingstpimm`immerr`timingstpautobatch`autobatcherr;
    time:y[0];feedtime:y[8];
    `timingdatastp insert (first feedtime),(first time),curtime,((first time)-(first feedtime)),(curtime-(first time)),(curtime-(first feedtime));];
  if[(value `..tpmode) in `timingstpdefaultbatch`defaultbatcherr;
    `timingdatastp insert 1#select time,feedtime,consumertime,feedtotp,tptoconsumer,feedtoconsumer from 
      update consumertime:curtime,feedtotp:time-feedtime,tptoconsumer:curtime-time,feedtoconsumer:curtime-feedtime from y;];
 };

// Set up connection management and set the UPD function
.consumer.init:{
  .proc.loadf first (.Q.opt .z.x)[`config]
  .servers.startup[];
  `upd set (`singletp`singlestp`bulktp`bulkstp!1_value .consumer.upd)[.consumer.updmode];
  };