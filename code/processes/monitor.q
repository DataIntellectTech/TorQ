/TorQ Monitor Process

//configurable parameters for check monitoring
.monitor.configcsv:@[value;`.monitor.configcsv;first .proc.getconfigfile["monitorconfig.csv"]];                      //name of config csv to load in
.monitor.configstored:@[value;`.monitor.configstored;`];                                                             //name of stored table for save and reload
.monitor.runcheckinterval:@[value;`.monitor.runcheckinterval;0D00:00:05];                                            //interval to run checks  
.monitor.checkinginterval:@[value;`.monitor.checkinginterval;0D00:00:05];                                            //interval to make sure checks are not lagging                                                                                         
.monitor.cleartrackinterval:@[value;`.monitor.cleartrackinterval;0D01:00:00];                                       //interval to check tracks are under certain age in checktracker
.monitor.agecheck:@[value;`.monitor.agecheck;0D12:00:00];                                                           //if check over agecheck, delete from tracker
.monitor.lagtime:@[value;`.monitor.lagtime;0D00:01:00];                                                              //if check has been running over this time, set to neg

// set up the upd function to handle heartbeats
upd:{[t;x]
 $[t=`heartbeat;
	 [ // publish single heartbeat row to web pages 
	  .html.pub[`heartbeat;$[min (`warning`error in cols exec from x);x;[.hb.storeheartbeat[x];hb_x::x;select from .hb.hb where procname in x`procname]]]];
   t=`logmsg;
	  [ 
     insert[`logmsg;x]; 
	   // publish single logmsg row to web page
	   .html.pub[`logmsg;x];
     // publish all lmchart data - DEV - could publish single cols and update svg internally
     .html.pub[`lmchart;lmchart[]]];
   ()]}

subscribedhandles:0 0Ni

// subscribe to heartbeats and log messages on a handle
subscribe:{[handle]
 subscribedhandles,::handle;
 @[handle;(`.ps.subscribe;`heartbeat;`);{.lg.e[`monitor;"failed to subscribe to heartbeat on handle ",(string x),": ",y]}[handle]];
 @[handle;(`.ps.subscribe;`logmsg;`);{.lg.e[`monitor;"failed to subscribe to logmsg on handle ",(string x),": ",y]}[handle]];
 }
 
// if a handle is closed, remove it from the list
.z.pc:{if[y;subscribedhandles::subscribedhandles except y]; x@y}@[value;`.z.pc;{{[x]}}]

// Make the connections and subscribe
.servers.startup[]
subscribe each (exec w from .servers.SERVERS) except subscribedhandles;

// As new processes become available, try to connect 
.servers.addprocscustom:{[connectiontab;procs]
 .lg.o[`monitor;"received process update from discovery service for process of type "," " sv string procs,:()];
 .servers.retry[];
 subscribe each (exec w from .servers.SERVERS) except subscribedhandles;
 }
.servers.connectcustom:{[connectiontab] 
 .lg.o[`monitor;"created outgoing connections"];
 subscribe each (exec w from connectiontab) except subscribedhandles;
 }
 
// GUI
/- Table data functions - Return unkeyed sorted tables
hbdata:{0!`error`warning xdesc .hb.hb}
lmdata:{0!`time xdesc -20 sublist logmsg}

/- Chart data functions - Return unkeyed chart data
lmchart:{0!select errcount:count i by 0D00:05 xbar time from logmsg where loglevel=`ERR}
bucketlmchartdata:{[x] x:`minute$$[x=0;1;x];0!select errcount:count i by (0D00:00+x) xbar time from logmsg where loglevel=`ERR}

/- Data functions - These are functions that are requested by the front end
/- start is sent on each connection and refresh. Where there are more than one table it is wise to identify each one using a dictionary as shown
start:{.html.wssub each `heartbeat`logmsg`lmchart;
       .html.dataformat["start";(`hbtable`lmtable`lmchart)!(hbdata[];lmdata[];lmchart[])]}
bucketlmchart:{.html.dataformat["bucketlmchart";enlist bucketlmchartdata[x]]}
monitorui:.html.readpagereplaceHP["index.html"]

// initialise pubsub
.html.init`heartbeat`logmsg`lmchart

//function to iniitialise process check monitoring- checks for last saved config file
initcheck:{
 if[not readstoredconfig[.monitor.configstored];
  readmonitoringconfig[.monitor.configcsv]]};

// specify .z.exit to save config
// capture any prior definition
.z.exit:{[x;y] saveconfig[.monitor.configstored;checkconfig];x@y}[@[value;`.z.exit;{{[x]}}]]

//initialise monitor checks
initcheck[]

//Timers
.timer.repeat[.proc.cp[];0Wp;.monitor.runcheckinterval;(`runnow;`);"run the monitoring checks"]
.timer.repeat[.proc.cp[];0Wp;.monitor.checkinginterval;(`checkruntime;.monitor.lagtime);"update status if running slow"]
.timer.repeat[.proc.cp[];0Wp;.monitor.cleartrackinterval;(`cleartracker;.monitor.agecheck);"delete rows if over certain age"]
