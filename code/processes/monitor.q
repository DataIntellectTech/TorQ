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

// GUI

// initialise pubsub
.html.init`heartbeat`logmsg`lmchart

/- Table data functions - Return unkeyed sorted tables
hbdata:{0!`error`warning xdesc .hb.hb}
lmdata:{0!`time xdesc -20 sublist logmsg}

/- Chart data functions - Return unkeyed chart data
lmchart:{0!select errcount:count i by 0D00:05 xbar time from logmsg where loglevel=`ERR}
bucketlmchartdata:{[x] x:`minute$$[x=0;1;x];0!select errcount:count i by (0D00:00+x) xbar time from logmsg where loglevel=`ERR}

/- Data functions - These are functions that are requested by the front end
/- start is sent on each connection and refresh. Where there are more than one table it is wise to identify each one using a dictionary as shown
start:{.html.wssub each `heartbeat`logmsg`lmchart;
       .html.dataformat["start";(`hbtable`lmtable`lmchart)!(hbdata[];lmdata[];lmchart[])] }
bucketlmchart:{.html.dataformat["bucketlmchart";enlist bucketlmchartdata[x]]}

monitorui:.html.readpagereplaceHP["index.html"]
