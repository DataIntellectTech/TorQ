// This is an asynchronous gateway. For sync calls, use deferred sync e.g. (neg h)"query";result:h[]
// There is a synchronous method, but it should be avoided unless absolutely required
// e.g. when using a non-native API which doesn't support deferred sync.
// Most of the notes and implementation refer to the asynchronous method.  The sync methods cause the gateway to block
// and therefore limit the number of queries that can be serviced at the same time.

// Queries are routed across heterogenous servers as they become available. Each query can query multiple servers, and the different
// parts of the query will be executed as the required back end server becomes available.
// When all the backend results are available, they will be joined together and returned to the client
// Generally speaking, each back end server will only have one query queued at once.  When it returns its result, it will be given 
// the next query.
// Queries which fail on the back end are not automatically re-run.  It is up to the client to re-submit it if required.

// There are a couple of calls to be used
// .gw.addserver[handle;servertype]
// is used to add a server of the specified type on the given handle. servertype would be for example `hdb or `rdb
// When a client queries they can use a simple method or a more advanced method
// .gw.asyncexec[query;servertypes(list of symbols)]
// will execute the supplied query on each of the specified server types, and raze the results
// .gw.asyncexecjpt[query;servertypes(list of symbols);joinfunction(lambda);postbackfunction(symbol);timeout(timespan)]
// allows the client to specify how the results are joined, posted back and timed out.
// The join function should be a monadic lambda - the parameter is the list of results
// The postback function is the function which will be called back in the client.  It should be a diadic function as both 
// the query that was run, and the result are posted back.  The postback can be the name of a function or a lambda.  The client
// can also post up functions with > 2 parameters, as long as the extra parameters are also sent e.g. 
// ({[a;b;query;result] ... };`a;`b) is valid
// To not use a postback function, send up the empty list ()
// i.e. the same as a deferred sync call
// The timeout value is used to return an error to the client if the query has been waiting / running too long
// asyncexec is equivalent to asyncexecjpt with joinfunction=raze, postbackfunction=`, timeout=0Wn

// The synchronous calls are 
// .gw.syncexec[query;servertypes(list of symbols)]
// which will parallelise the queries across the backend servers, but block at the front end (so only 1 client query can be processed at a time)
// the results will be razed and returned to the client
// .gw.syncexecj[query;servertypes(list of symbols);joinfunction(lambda)]
// allows the client to specify the join function

// Error handling
// errors are returned as strings (it's the only way to do it if we have to assume q and non-q clients)
// each error will be prefixed with the errorprefix (currently "error: ")
// the client should check if the result is a string, and if it is if it is prefixed with "error: "
// errors will be returned when 
//	a) the query times out
// 	b) a back end server returns an error
// 	c) the join function fails
// 	d) a back end server fails
// 	e) the client requests a query against a server type which currently isn't active (this error is returned immediately)
// If postback functions are used, the error string will be posted back within the postback function 
// (i.e. it will be packed the same way as a valid result)

// If the client closes connection before getting results, the back end servers will still continue to execute
// Each of the remaining client queries will be unqueued.
// If a back end server fails, the clients which are waiting for a result will be returned an error.

// The servers which are available is decided using .gw.availableservers[] function.  This returns a dictionary of handle!servertype
// Currently this will return all registered and active handles.  If you wish to modify the routing, change this function.  Examples
// might be to change it so only servers in the same datacentre or country are used, unless there are none available (i.e. only 
// route queries over a WAN if there isn't any other option).  To work out where a server is, it needs to report the information
// in the .proc.getattributes[] call.  The data will automatically be populated in the .gw.servers table.
// When synchronous calls are used, errors are returned to the client rather than strings.

// The next query to execute is decided using the .gw.getnextqueryid[] function.  Currently this is a simple FIFO queue (.gw.fifo)
// for more sophisticated algorithms e.g. priority queues based on user name, ip address, usage so far, the query that is being run etc.
// set .gw.getnextqueryid to be something else.  It should return a 1 row table containing all the query details.

// server stats are collected in .gw.servers
// client info is in .gw.clients
// query info is in .gw.queryqueue

// To create a simple homogenous gateway (i.e. all backend servers are the same) you create projections of 
// addserver and asyncexec, with the (servertypes) parameter projected to a single server of (for example) `standardserver

\d .gw

synccallsallowed:@[value;`.gw.synccallsallowed; 0b]		// whether synchronous calls are allowed
querykeeptime:@[value;`.gw.querykeeptime; 0D00:30]		// the time to keep queries in the 
errorprefix:@[value;`.gw.errorprefix; "error: "]		// the prefix for clients to look for in error strings

// Track query IDs
queryid:0
nextqueryid:{.gw.queryid:.gw.queryid+1;.gw.queryid}

// Store the incoming queries
queryqueue:([queryid:`u#`long$()] time:`timestamp$(); clienth:`g#`int$(); query:(); servertype:(); join:(); postback:(); timeout:`timespan$(); submittime:`timestamp$(); returntime:`timestamp$(); error:`boolean$())

// client details
clients:([]time:`timestamp$(); clienth:`g#`int$(); user:`symbol$(); ip:`int$(); host:`symbol$())

// structure to store query results from back end servers
// structure is queryid!(clienthandle;servertype!(handle;results))
results:(enlist 0Nj)!enlist(0Ni;(enlist `)!enlist(0Ni;::))  

// server handles - whether the server is currently running a query
servers:([handle:`int$()] servertype:`symbol$(); inuse:`boolean$();active:`boolean$();querycount:`int$();lastquery:`timestamp$();usage:`timespan$();attributes:())
addserverattr:{[handle;servertype;attributes] `.gw.servers upsert (handle;servertype;0b;1b;0i;0Np;0D;attributes)}
addserver:addserverattr[;;()!()]
setserverstate:{[serverh;use] 
 $[use;
   update inuse:use,lastquery:.z.p,querycount+1i from `.gw.servers where handle in serverh;
   update inuse:use,usage:usage+.z.p - lastquery from `.gw.servers where handle in serverh]}

// return a list of available servers
// override this function for different routing algorithms e.g. maybe only send to servers in the same datacentre, country etc.
// use the attributes as required
availableservers:{[excludeinuse] 
 $[excludeinuse;
  exec handle!servertype from servers where active, not inuse;
  exec handle!servertype from `inuse xasc select handle,servertype,inuse from servers where active]}

// join the queryqueue and client details together
queryandclients:{aj[`clienth`time;queryqueue;clients]}

// get the table of queries which can be run based on the available servers and those which are waiting
canberun:{
 // check if it's possible to run anything
 if[0=count avail:distinct value availableservers[1b];
	update required:(),available:(),handles:() from 0#0!queryqueue];
 select from 
  (update available:required inter\:avail from
   (update required:(where each null each .gw.results[;1;;0])[queryid] from 
     (update required:servertype from 
      select from 0!queryqueue where null returntime)
    where queryid in key .gw.results))
 where 0<count each available}

// Manage client queries
addquerytimeout:{[query;servertype;join;postback;timeout] `.gw.queryqueue upsert (nextqueryid[];.z.p;.z.w;query;servertype,();join;postback;timeout;0Np;0Np;0b)}
removeclienthandle:{
 update submittime:2000.01.01D0^submittime,returntime:2000.01.01D0^returntime from `.gw.queryqueue where clienth=x;
 deleteresult exec queryid from .gw.queryqueue;}
addclientdetails:{`.gw.clients insert (.z.p;x;.z.u;.z.a;.z.h)}
removequeries:{[age] 
 .gw.queryqueue:update `u#queryid,`g#clienth from delete from (update `#clienth from queryqueue) where .z.p > returntime+age}

// scheduling function to get the next query to execute. Need to ensure we avoid starvation
// possibilities : 
//  fifo
//  low utilisation (handles which have used it least), 
//  low utilisation last x minutes 
//  handle longest wait (the handle which has been waiting the longest without any query being serviced)
//  low query count (handle with least queries run)
//  low query count last x minutes 
fifo:{1 sublist select from canberun[] where time=min time}
getnextqueryid:fifo
getnextquery:{
 qid:getnextqueryid[];
 if[0=count qid; :()];
 update submittime:.z.p^submittime from `.gw.queryqueue where queryid in qid`queryid;
 qid}

// finish a query
// delete the temp results
// update the status, set the return time
// reset the serverhandle
finishquery:{[qid;err;serverh] 
 deleteresult[qid];
 update error:err,returntime:.z.p from `.gw.queryqueue where queryid in qid;
 setserverstate[serverh;0b];
 }  

// Get a list of pending and running queries
getqueue:{select queryid,time,clienth,query,servertype,status:?[null submittime;`pending;`running],submittime from .gw.queryqueue where null returntime}

// manage the result set dictionaries
addemptyresult:{[queryid; clienth; servertypes] results[queryid]:(clienth;servertypes!(count servertypes,:())#enlist(0Ni;::))}
addservertoquery:{[queryid;servertype;serverh] .[`.gw.results;(queryid;1);{.[x;(y 0;0);:;y 1]};(servertype;serverh)]}
deleteresult:{[queryid] .gw.results : (queryid,()) _ .gw.results}

// add a result coming back from a server
addserverresult:{[queryid; results] 
 if[queryid in key .gw.results; .[`.gw.results;(queryid;1;first .gw.results[queryid;1;;0]?.z.w;1);:;results]];
 setserverstate[.z.w;0b];
 runnextquery[];
 checkresults[queryid]}
// handle an error coming back from the server
addservererror:{[queryid;error]
 // propagate the error to the client
 sendclientreply[queryid;.gw.errorprefix,error];
 setserverstate[.z.w;0b];
 runnextquery[];
 // finish the query
 finishquery[queryid;1b;0Ni];
 }
// check if all results are in.  If so, send the results to the client
checkresults:{[queryid]
 if[not any (::)~/: value (r:.gw.results[queryid])[1;;1];
  // get the rest of the detail from the query table
  querydetails:queryqueue[queryid];
  // apply the join function to the results
  // If there only is one result, then just return it - ignore the join function
  res:@[{(0b;$[1<count y;$[10h=type x;value(x;y); x @ y];first y])}[querydetails[`join]];value r[1;;1];{(1b;.gw.errorprefix,"failed to apply join function to result sets: ",x)}];
  // send the results back to the client.
  sendclientreply[queryid;last res];
  // finish the query
  finishquery[queryid;res 0;0Ni]];}

// build and send a response to go to the client
// if the postback function is defined, then wrap the result in that, and also send back the original query
sendclientreply:{[queryid;result]
 querydetails:queryqueue[queryid];
 tosend:$[()~querydetails[`postback];
	result;
	(querydetails`postback),(enlist querydetails`query),enlist result];
 @[neg querydetails`clienth;tosend;()]}

// execute a query on the server.  Catch the error, propagate back
serverexecute:{[queryid;query] 
 res:@[{(0b;value x)};query;{(1b;"failed to run query on server ",(string .z.h),":",(string system"p"),": ",x)}];
 // send back the result, in an error trap
 @[neg .z.w; $[res 0; (`.gw.addservererror;queryid;res 1); (`.gw.addserverresult;queryid;res 1)]; ()];}
// send a query to a server 
sendquerytoserver:{[queryid;query;serverh]
 (neg serverh,:())@\:(serverexecute;queryid;query);
 setserverstate[serverh;1b];}

// handle is closed by a server
removeserverhandle:{[serverh]
 if[null servertype:first exec servertype from .gw.servers where handle=serverh; :()];
 // get the list of effected query ids
 qids:where serverh in' value each results[;1;;0];
 // propagate an error back to each client
 sendclientreply[;.gw.errorprefix,"backend ",(string servertype)," server handling query closed the connection"] each qids;
 finishquery[qids;1b;serverh]; 
 // mark the server as inactive
 update active:0b from `.gw.servers where handle=serverh;
 runnextquery[];
 }

// timeout queries
checktimeout:{
 qids:exec queryid from .gw.queryqueue where not timeout=0Wn,.z.p > time+timeout,null returntime;
 // propagate a timeout error to each client
 if[count qids;
  sendclientreply[;.gw.errorprefix,"query has exceeded specified timeout value"] each qids;
  finishquery[qids;1b;0Ni]];
 }

// execute - called by a client
asyncexecjpt:{[query;servertype;joinfunction;postback;timeout]
 // check if we have all the servers active
 if[count missing:(servertype,:()) except exec distinct servertype from .gw.servers where active;
  res:.gw.errorprefix,"not all of the requested server types are available; missing "," " sv string missing;
  @[neg .z.w;$[()~postback;res;$[-11h=type postback;enlist postback;postback],(enlist query),enlist res];()];
  :()];
 addquerytimeout[query;servertype;joinfunction;postback;timeout];
 runnextquery[];
 }
asyncexec:asyncexecjpt[;;raze;();0Wn]

// execute a synchronous query
syncexecj:{[query;servertype;joinfunction]
 if[not .gw.synccallsallowed; '`$"synchronous calls are not allowed"]
 // check if we have all the servers active
 if[count missing:(servertype,:()) except exec distinct servertype from .gw.servers where active;
  '`$"not all of the requested server types are available; missing "," " sv string missing]; 
 // get the list of handles
 handles:(servers:availableservers[0b])?servertype;
 start:.z.p;
 setserverstate[handles;1b];
 // to allow parallel execution, send an async query up each handle, then block and wait for the results
 (neg handles)@\:({@[neg .z.w;@[{(1b;.z.p;value x)};x;{(0b;.z.p;x)}];()]};query);
 // flush
 (neg handles)@\:(::);
 // block and wait for the results
 res:handles@\:(::);
 // update the usage data
 update inuse:0b,usage:usage+(handles!res[;1] - start)[handle] from `.gw.servers where handle in handles;
 // check if there are any errors in the returned results
 $[all res[;0];
  // no errors - join the results
  @[joinfunction;res[;2];{'`$"failed to apply supplied join function to results: ",x}];
  [failed:where not res[;0];
   '`$"queries failed on server(s) ",(", " sv string servers[handles failed]),".  Error(s) were ","; " sv res[failed][;2]]] 
 }
syncexec:syncexecj[;;raze]

// run a query
runquery:{[]
 // check if there is something to run
 if[count torun:getnextquery[];
  torun:first torun;
  // if it isn't already in the result dict, add it
  if[not torun[`queryid] in key results;
   addemptyresult[torun`queryid;torun`clienth;torun`servertype]];
  // update the results dictionary and send off the queries
  // get the handles to run on
  handles:availableservers[1b]?torun`available;
  // update the results dictionary
  addservertoquery[torun`queryid;torun`available;handles]; 
  // send off the queries
  sendquerytoserver[torun`queryid;torun`query;handles]];
 } 
runnextquery:runquery


// when a new connection is opened, add client details
po:{addclientdetails[x]}

// called when a handle is closed
pc:{
 removeclienthandle[x];
 removeserverhandle[x];}

// override message handlers
.z.pc:{x@y; .gw.pc[y]}@[value;`.z.pc;{{[x]}}]
.z.po:{x@y; .gw.po[y]}@[value;`.z.po;{{[x]}}]
/ .z.pg:{x@y; '.gw.errorprefix,"no synchronous queries allowed"}@[value;`.z.pg;{[x]}]

// START UP
// initialise connections
.servers.startup[]

// add servers from the standard connections table
addserversfromconnectiontable:{
 {.gw.addserverattr'[x`w;x`proctype;x`attributes]}[select w,proctype,attributes from .servers.SERVERS where proctype in x,not w in ((0;0Ni),exec handle from .gw.servers where active)];}

// When new connections come in from the discovery service, try to reconnect
.servers.addprocscustom:{[connectiontab;procs]
 // retry connections
 .servers.retry[];
 // add any new connections
 .gw.addserversfromconnectiontable[.servers.CONNECTIONS];
 // See if any queries can now be run
 runnextquery[]}
 
addserversfromconnectiontable[.servers.CONNECTIONS]

// Add calls to the timer
if[@[value;`.timer.enabled;0b];
 .timer.repeat[.z.p;0Wp;0D00:05;(`.gw.removequeries;.gw.querykeeptime);"Remove old queries from the query queue"];
 .timer.repeat[.z.p;0Wp;0D00:00:05;(`.gw.checktimeout;`);"Timeout queries which have been waiting too long"]];

// add in some api details 
/ if[`add in key `.api;
.api.add[`.gw.asyncexecjpt;1b;"Execute a function asynchronously.  The result is posted back to the client either directly down the socket (in which case the client must block and wait for the result - deferred synchronous) or wrapped in the postback function";"[(string | mixed list): the query to execute; symbol(list): the list of servers to query against; lambda: the function used to join the resulting data; symbol or lambda: postback;timespan: query timeout]";"The result of the query either directly or through the postback function"]
.api.add[`.gw.asyncexec;1b;"Execute a function asynchronously.  The result is posted back to the client directly down the socket. The client must block and wait for the result - deferred synchronous.  Equivalent to .gw.asyncexecjpt with join function of raze, no postback and no timeout";"[(string | mixed list): the query to execute; symbol(list): the list of servers to query against]";"The result of the query"]
.api.add[`.gw.syncexecj;1b;"Execute a function asynchronously, join the results with the specified join function";"[(string | mixed list): the query to execute; symbol(list): the list of servers to query against; lambda: the function used to join the resulting data]";"The result of the query"];
.api.add[`.gw.syncexec;1b;"Execute a function asynchronously, use raze to join the results";"[(string | mixed list): the query to execute; symbol(list): the list of servers to query against]";"The result of the query"];
.api.add[`.gw.getqueue;1b;"Return the current queryqueue with status";"[]";"table: the current queryqueue with either pending or running status"];
