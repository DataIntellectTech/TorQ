//Process which takes in configurable process specific checks and is called as part of monitor process
//Get handle to other TorQ process specified
gethandle:{exec first w from .servers.getservers[`procname;x;()!();1b;1b]}

// table of check statuses - i.e. the result of the last run
checkstatus:(
  [checkid:`int$()]              // id of the check
  family:`symbol$();             // the family of checks
  metric:`symbol$();             // specific check
  process:`symbol$();            // process it was run on 
  lastrun:`timestamp$();         // last time it was run
  nextrun:`timestamp$();         // next time it will be run
  status:`short$();              // status 
  executiontime:`timespan$();    // time the execution took
  totaltime:`timespan$();        // total time- including the network transfer time+queue time on target
  timerstatus:`short$();         // whether the check run in the correct amount of time
  running:`short$();             // whether the check is currently running
  result:())                     // error message

// the table of checks to run
checkconfig:(
  [checkid:`int$()]              // id of the check
  family:`symbol$();             // the family of checks
  metric:`symbol$();             // specific check
  process:`symbol$();            // process it was run on
  query:();                      // query to execute
  resultchecker:();              // function to run on the result
  params:();                     // the parameters to pass to query and resultchecker
  period:`timespan$();           // how often to run it
  runtime:`timespan$();          // how long it should take to run
  active:`boolean$())            // whether the check is active or not

// table to track the monitoring requests we have in flight
// we don't have any trimming functionality for this table, we may need to add that
checktracker:(
  [runid:`u#`int$()]             // id of the run
  sendtime:`timestamp$();        // the time we sent the request
  receivetime:`timestamp$();     // the time the response was received
  executiontime:`timespan$();    // the time it took to run the query
  checkid:`int$();               // the id of the check that was run
  status:`short$();              // the status of the request
  result:())                     // the result of the request

// insert placeholder row to make sure result field doesn't inherit a type
`checktracker insert (0Ni;0Np;0Np;0Nn;0Ni;0Nh;());

// initialise the runid to 0
runid:0i

duplicateconfig:{[t] update process:raze[t `process] from ((select from t)where count each t[`process])};

readmonitoringconfig:{[file]
  // read in config CSV (actually pipe delimited)
  .lg.o["reading monitoring config from ",string file:hsym file];
  // read in csv file, trap error
  c:.[0:;(("SS****NN";enlist"|");file);{.lg.e["failed to load monitoring configuration file: ",x]}];
  //ungroup checks and make new row for each process
  // attempt to parse the params value
  p:{@[value;x;{[x;y;e] .lg.e["failed to parse param value from config file at row ",(string y)," with definition ",x,": ",e];exit 2}[x;y]]}'[c`params;til count c];
  // check each params value is a dictionary
  if[not all 99h=type each p;
    .lg.e["all param values must have type dictionary. Values at rows ",(.Q.s1 where not 99h=type each p)," do not"];
    exit 3
  ];
  //ungroup checks and make new row for each process
  //c:update params:p from c;
  c:duplicateconfig[update params:p from update`$";"vs/:process from c];
  addconfig c;
 }

readstoredconfig:{[file]
  // read in the stored config file. Return true or false status
  // check for existence 
  if[any null file;
    .lg.o["supplied stored config file location is null: not attempting to read stored config"];
    :0b
  ];
  if[()~key file:hsym file;
    .lg.o["could not find storedconfig file at ",string file];
    :0b];
    .lg.o["reading stored config file from ",string file];
    @[{addconfig get x};file;{'"failed to read stored config file: ",x}
  ];
  1b
 }

saveconfig:{[file;config]
  // write the in-memory config to disk
  if[null file;:()];
  .lg.o["saving stored config to ",string file:hsym file];
  .[set;(file;config);{'"failed to write config file to ",(string x),": ",y}file] 
 }

addcheck:{[checkdict]
  // add a new monitoring check
  // this is for manual adds - add it as a dictionary
  if[not 99h=type checkdict;'"input must be a dictionary"];
  if[not all (req:`family`metric`process`query`resultchecker`params`period`runtime)in key checkdict;
    '"not all required dictionary keys supplied; missing ",.Q.s1 req except key checkdict];
  if[not 11h=type checkdict`family`metric`process;
    '"keys family, metric, process must have type symbol"];
  if[not all 10h=type each checkdict`query`resultchecker;         
    '"keys query, resultchecker must have type char array (string)"];
  if[not all 16h=type checkdict`period`runtime;
    '"keys period, runtime must have type timespan"];
  if[not 99h=type checkdict`params;
    '"key params must have type dictionary"];
  // add the config
  addconfig enlist req#checkdict;
 }

addconfig:{
  // function to insert to check config table, and into checkstatus
  // input is a table of config checks
  // pull out the current max checkid
  nextcheckid:1i+0i|exec max checkid from checkconfig;
  // add checkid if not already present
  if[not `checkid in cols x; x:update checkid:nextcheckid+til count x from x];
  // add active if not already present
  if[not `active in cols x; x:update active:1b from x];
 
  // select only the columns we need, and key it
  x:`checkid xkey (cols checkconfig)#0!x;
 
  // insert to checkconfig
  `checkconfig upsert x;

  // and insert to checkstatus
  `checkstatus upsert select checkid,family,metric,process,lastrun:0Np,nextrun:.z.p,status:0Nh,executiontime:0Nn,totaltime:0Nn,timerstatus:0Nh,running:0Nh,result:(count process)#() from x;  
 }

copyconfig:{[checkid;newproc]
  //function to copy config from checkconfig table and reinsert with new target process
  //check if supplied checkid exists
  if[not checkid in exec checkid from checkconfig;
    '"supplied checkid doesn't exist in checkconfig table"];
  newcheck:update process:newproc from delete checkid from exec from checkconfig where checkid=checkid;
  addcheck newcheck
 }

togglecheck:{[cid;status]
  if[not cid in exec checkid from checkconfig; '"checkid ",(string cid)," doesn't exist"];
  update active:status from `checkconfig where checkid=cid;
 }

disablecheck:togglecheck[;0b]
enablecheck:togglecheck[;1b]

// input to runcheck will be a row from checkconfig
runcheck:{
  // increment the run id
  runid+:1i;
  // get the handle to the process
  if[null h:gethandle[x`process]; `checkstatus upsert ((enlist`checkid)!enlist x`checkid),update running:0h,result:"no handle connection",status:0h,timerstatus:0h from checkstatus x`checkid];
  // run the check remotely
  // send over the id, return a dict of `id`status`res
  .async.postback[h;({start:.z.p; (`runid`executiontime!(y;.z.p-start)),`status`result!@[{(1h;value x)};x;{(0h;x)}]};(x`query;x`params);runid);`checkresulthandler];

  // add a record to track 
  `checktracker insert (runid;.z.p;0Np;0Nn;x`checkid;0Nh;());
  // update the status to be running 
  `checkstatus upsert ((enlist`checkid)!enlist x`checkid),update running:1h from checkstatus x`checkid;
 } 

//check that process has not been running over next allotted runtime
//if so, set status and timerstatus to neg
checkruntime:{[n]
  update status:0h,timerstatus:0h,running:0h from `checkstatus where running=1h,n<.z.p-nextrun;
 }

checkresulthandler:{
  // update the appropriate record in checktracker
  toinsert:((enlist`runid)#x),(checktracker x`runid),((enlist`receivetime)!enlist .z.p),`executiontime`status`result#x;

  // store the record
  `checktracker upsert toinsert; 

  // get the configuration for this alert 
  conf:checkconfig toinsert`checkid;
 
  // need to run the resultchecker against the actual result
  // but only if the actual query has been successful
   if[x`status; 
     // pull out the resultchecker function and run it
     // this should only get triggered in dev cycle- 
     // protect against devs inserting incorrect resultchecker definitions
     r:@[value;(conf`resultchecker;conf`params;toinsert);{`status`result!(0b;"failed to run result checker for runid ",(string x`runid)," and checkid ",(string x`checkid),": ",y)}[toinsert]];
     // have to make sure we have dictionary result
    if[not 99h=type r; r:`status`result!(0b;"resultchecker function did not return a dictionary")];
    // check here if it has failed or passed
    // override the status and error message as appropriate
    toinsert[`status]&:r`status;
    toinsert[`result]:r`result; 
  ];
 
 // if the query has failed, add in the error
  if[not x`status; toinsert[`result]:"request failed on remote server: ",x`result];
 
  // insert the record into checkstatus
  `checkstatus upsert ((enlist `checkid)!enlist toinsert`checkid),
  (checkstatus toinsert[`checkid]), 
  `lastrun`nextrun`status`executiontime`totaltime`timerstatus`running`result!(toinsert`sendtime;.z.p+conf`period;toinsert`status;toinsert`executiontime;toinsert[`receivetime]-toinsert[`sendtime];`short$conf[`runtime]>toinsert`executiontime;0h;toinsert`result)
 } 

// run each check that needs to be run
runnow:{
  // run each check which hasn't been run recently enough
  runcheck each 0!select from checkconfig where active, checkid in exec checkid from checkstatus where .z.p>nextrun,not running=1h;
 }

//Check median sendtimes against variable input timespan
timecheck:{[n]
  //Extract median time from checkstatus, check against input,return true if median is less than n
  select medtime,loadstatus:n>medtime from select medtime:`timespan$med (totaltime-executiontime) from checkstatus
 }

// SUPPORT API 
//Update config based on checkid
updateconfig:{[checkid;paramkey;newval]
  // update a config value 
  if[not checkid in exec checkid from checkconfig;
    '"supplied checkid doesn't exist in checkconfig table"
  ];
  // check existance
  if[not paramkey in key current:.[`checkconfig;(checkid;`params)];
    '"supplied paramkey does not exist in params for checkid ",(string checkid)
  ];
  // check type
  if[not type[newval]=type current paramkey;
    '"supplied value type ",(string type newval)," doesn't match current type ",string type current paramkey
  ];
  // crack on
  .[`checkconfig;(checkid;`params;paramkey);:;newval]; 
 }

forceconfig:{[checkid;newconfig]
  // force config over the top of current
  // don't check for existence of parameters,parameter types etc. 
  if[not checkid in exec checkid from checkconfig;
    '"supplied checkid doesn't exist in checkconfig table"
 ];
  if[not 99h=type newconfig; '"new supplied config must be of type dictionary"];
  .[`checkconfig;(checkid;`params);:;newconfig];
 }

//Function to update config value based on family and metric combination
updateconfigfammet:{[f;m;paramkey;newval]
  if[0=count checkid: exec checkid from checkconfig where family=f,metric=m;
    '"family and metric combination doesn't exist in checkconfig table"
  ];
    updateconfig[first checkid;paramkey;newval];
 }

//Function to return only required metrics on current status of check
currentstatus:{[c]
  if[all null c; :select checkid,family,metric,process,status,timerstatus,running,result from checkstatus];
  :select checkid,family,metric,process,status,timerstatus,running,result from checkstatus where checkid in c;
 }

//Get ordered status and timer status by family
//If null return fulltable
statusbyfam:{[f]
  if[all null f;:`status`timerstatus xasc select from checkstatus];
  `status`timerstatus xasc select from checkstatus where family in f
 }

//Clear checks in checktracker older than certain age
cleartracker:{[time]
  delete from `checktracker where (.z.p-sendtime)> time
 }
 
// RESULT HANDLERS
// some example result handler functions here 
// these should always return `status`result!(status; message)
// they should take two params- p (dictionary parameters) and r (resultrow)

checkcount:{[p;r]
  if[`morethan=p`cond;
    if[p[`count]<r`result; :`status`result!(1h;"")];
  :`status`result!(0h;"variable ",(string p`varname)," has count of ",(string r`result)," but requires ",string p`count)
   ];
 if[`lessthan=p`cond;
   if[p[`count]>r`result; :`status`result!(1h;"")];
   :`status`result!(0h;"variable ",(string p`varname)," has count of ",(string r`result)," but should be less than ",string p`count)
  ];
 }

queuecheck:{[p;r]
  if[not count where any each(r`result)>p`count;:`status`result!(1h;"")];
  `status`result!(0h;"There are slow subscribers to publisher that have message queues longer than ",string p`count)
 }

truefalse:{[p;r]
   if[`true=p`cond;
    if[1b=r`result; :`status`result!(1h;"")];
  :`status`result!(0h;"variable ",(string p`varname),"is returning false, but should return true")
   ];
 if[`false=p`cond;
   if[0b=r`result; :`status`result!(1h;"")];
  :`status`result!(0h;"variable ",(string p`varname),"is returning true, but should return false")
  ];
 }

resulttrue:{[p;r]
  if[(r`result)=p`result;:`status`result!(1h;"")];
  `status`result!(0h;"The variable ",(string p`varname),"is returning ",(string r`result)," but should be returning ",string p`result)
 }

