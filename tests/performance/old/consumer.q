// dummy consumer for stp vs tp performance comparison

tpmode:`timingstpautobatch                   // [timingtp|timingstpimm|timingstpautobatch|timingstpdefaultbatch|immerr] for choosing correct upd definition
updmode:`singlestp                           // [singletp|singlestp|bulktp|bulkstp] for choosing correct upd function

// empty table schemas for timestamp inserts
timingtp:([]time:`timestamp$(); feedtime:`timestamp$(); consumertime:`timestamp$(); feedtotp:`timespan$(); tptoconsumer:`timespan$(); feedtoconsumer:`timespan$())
timingstp:([]time:`timestamp$(); feedtime:`timestamp$(); consumertime:`timestamp$(); feedtotp:`timespan$(); tptoconsumer:`timespan$(); feedtoconsumer:`timespan$())
timingdatatp:([]time:`timestamp$(); feedtime:`timestamp$(); consumertime:`timestamp$(); feedtotp:`timespan$(); tptoconsumer:`timespan$(); feedtoconsumer:`timespan$())
timingdatastp:([]time:`timestamp$(); feedtime:`timestamp$(); consumertime:`timestamp$(); feedtotp:`timespan$(); tptoconsumer:`timespan$(); feedtoconsumer:`timespan$()) 

\d .consumer
// upd functions to test single messages many times for tp and stp

// single message insert for old TP
updsingleTP:{
  curtime:.z.p;
  `timingtp insert delete sym from update consumertime:curtime, feedtotp:time-feedtime, tptoconsumer:curtime-time, feedtoconsumer:curtime-feedtime from y;
 };

// expects single list to insert into table
updsingleSTP:{
  curtime:.z.p;
  if[(value `..tpmode) in `timingstpdefaultbatch`defaultbatcherr`timingstpautobatch`autobatcherr;
    `timingstp insert delete sym from update consumertime:curtime, feedtotp:time-feedtime, tptoconsumer:curtime-time, feedtoconsumer:curtime-feedtime from y;];
  if[(value `..tpmode) in `timingstpimm`immerr;
    stptime:y[0];feedtime:y[2]; 
    `timingstp insert stptime,feedtime,curtime,(stptime-feedtime),(curtime-stptime),(curtime-feedtime);];
 };

// upd functions to test multiple entries of dummy data for each message
updbulkTP:{
  curtime:.z.p;
  `timingdatatp insert 1#select time,feedtime,consumertime,feedtotp,tptoconsumer,feedtoconsumer from 
    update consumertime:curtime,feedtotp:time-feedtime,tptoconsumer:curtime-time,feedtoconsumer:curtime-feedtime from y;
 };

// timestamp is same for each message, keep only one
updbulkSTP:{
  curtime:.z.p;
  if[(value `..tpmode) in `timingstpimm`immerr`timingstpautobatch`autobatcherr;
    time:y[0];feedtime:y[8];
    `timingdatastp insert (first feedtime),(first time),curtime,((first time)-(first feedtime)),(curtime-(first time)),(curtime-(first feedtime));];
  if[(value `..tpmode) in `timingstpdefaultbatch`defaultbatcherr;
    `timingdatastp insert 1#select time,feedtime,consumertime,feedtotp,tptoconsumer,feedtoconsumer from 
      update consumertime:curtime,feedtotp:time-feedtime,tptoconsumer:curtime-time,feedtoconsumer:curtime-feedtime from y;];
 };

// get connections and subscribe to TP or STP
// define upd to top level namespace
\d .
.servers.CONNECTIONS:.consumer.tickerplanttypes
.servers.startup[]

// SUBSCRIPTION LOGIC

//h:hopen`::TPHANDLE:admin:admin
//{h(`.u.sub;x;`)} each `quote`quote_iex`trade`trade_iex`timing0`timing1`timingdata0`timingdata1

getupd:{
  if[updmode~`singletp;:.consumer.updsingleTP];
  if[updmode~`singlestp;:.consumer.updsingleSTP];
  if[updmode~`bulktp;:.consumer.updbulkTP];
  if[updmode~`bulkstp;:.consumer.updbulkSTP];
 };

upd:getupd[]

// function to get all the above stats together:
// takes in [timingtp or timingstp or timingdatatp or timingdatastp; name choice of timing csv; name choice of msg count csv]
getstats:{[tab;name1;name2]
  // get middle 30 seconds of data as the sample
  t:select from tab where time within ((((first tab)`time)+15000000000);((first tab)`time)+45000000000);
  // get tp -> consumer and feed -> consumer times
  midtimes:value exec feedtotp,tptoconsumer,feedtoconsumer from t;
  medians:`timespan$med each midtimes;
  averages:`timespan$avg each midtimes;
  maximums:`timespan$max each midtimes;
  // drift calculation
  top:(floor (count tab)*.10)#tab;           // get first 10% of sample
  bot:(neg floor (count tab)*.10)#tab;       // get last 10% of sample  
  medtop:`timespan$med each exec feedtotp,tptoconsumer,feedtoconsumer from top;
  medbot:`timespan$med each exec feedtotp,tptoconsumer,feedtoconsumer from bot;
  drift:medtop-medbot;
  statstime:`med`avg`max`drift,'3 cut medians,averages,maximums,value drift;
  // get number of messages stats in mid 30 seconds sample
  seconds:1_select count i by time.second from t;
  maxmps:max seconds;         // max messages per second
  medmps:med seconds;         // median messages per second
  avgmps:avg seconds;         // average messages per second
  totalmsg: count t;          // total messages sent in middle 30 seconds sample
  // set tables of statistics
  `returntab1 set `stat xkey flip (`stat`feedtotp`tptoconsumer`feedtoconsumer)!flip statstime;
  `returntab2 set flip (`totalmsg`maxmps`medmps`avgmps)!totalmsg,value each (maxmps;medmps;avgmps);
  // save stats tables
  save `:returntab1.csv;
  save `:returntab2.csv;
  // move and rename stats tables
  if[not `timingstats in key`:.;system"mkdir timingstats"];
  system["mv returntab1.csv ","timingstats/",string[name1],".csv"];
  system["mv returntab2.csv ","timingstats/",string[name2],".csv"];
 };


// Test cases:

// SINGLE MODE:
// - [x] Old TP: getstats[timingtp;`timingtpimmsingle;`msgcounttpimmsingle]                                       
// - [x] Old TP batch publish (-t 100): getstats[timingtp;`timingtpbatchsingle;`msgcounttpbatchsingle]            
// - [x] STP immediate: getstats[timingstp;`timingstpimmsingle;`msgcountstpimmsingle]                              
// - [x] STP autobatching: getstats[timingstp;`timingstpautobatchsingle;`msgcountautobatchsingle]                 
// - [x] STP default batch (-t 100): getstats[timingstp;`timingstpdefaultbatchsingle;`msgcountdefaultbatchsingle] 
// - [x] STP error mode w/ immediate: getstats[timingstp;`timingstpimmerrsingle;`msgcountimmerrsingle]            

// BULK MODE:
// - [x] Old TP: getstats[timingdatatp;`timingtpimmbulk;`msgcounttpimmbulk] 
// - [x] Old TP batch publish (-t 100): getstats[timingdatatp;`timingtpbatchbulk;`msgcounttpbatchbulk] 
// - [x] STP immediate: getstats[timingdatastp;`timingdatastpimmbulk;`msgcountstpimmbulk]
// - [x] STP autobatching: getstats[timingdatastp;`timingdatastpautobatchbulk;`msgcountstpautobatchbulk]
// - [x] STP batch publish (-t 100): getstats[timingdatastp;`timingdatastpdefaultbatchbulk;`msgcountstpdefaultbatchbulk]
// - [x] STP error mode w/ immediate: getstats[timingdatastp;`timingdatastpimmerrbulk;`msgcountstpimmerrbulk]

// Notes:

// more than one process pushing data at TP and STP?
// timer wont register enough CPU usage - use while loop
// maybe have more than one publisher pushing data to TP?
// run feed for 1 minute with:
// now:.z.p; while[.z.p < now+0D00:01; call feed here]
