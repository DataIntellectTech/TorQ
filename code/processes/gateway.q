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

eod:0b		
seteod:{[b] .lg.o[`eod;".gw.eod set to ",string b]; eod::b;}    // called by wdb.q during EOD
checkeod:{[IDS].gw.eod&1<count distinct$[11h=type ids:raze IDS;ids;exec servertype from .gw.servers where any serverid in/:ids]}    // check if eod reload affects query


// Track query IDs
queryid:0
nextqueryid:{.gw.queryid:.gw.queryid+1;.gw.queryid}
serverid:0
nextserverid:{.gw.serverid:.gw.serverid+1; .gw.serverid}

// Store the incoming queries
queryqueue:([queryid:`u#`long$()] time:`timestamp$(); clienth:`g#`int$(); query:(); servertype:(); queryattributes:(); join:(); postback:(); timeout:`timespan$(); submittime:`timestamp$(); returntime:`timestamp$(); error:`boolean$();attributequery:`boolean$())

// client details
clients:([]time:`timestamp$(); clienth:`g#`int$(); user:`symbol$(); ip:`int$(); host:`symbol$())

// structure to store query results from back end servers
// structure is queryid!(clienthandle;servertype!(handle;results))
// structure is queryid!(clienthandle;(servertype or serverIDs)!(serverID;results))
results:(enlist 0Nj)!enlist(0Ni;(enlist `)!enlist(0Ni;::))  

// server handles - whether the server is currently running a query
servers:([serverid:`u#`int$()]handle:`int$(); servertype:`symbol$(); inuse:`boolean$();active:`boolean$();querycount:`int$();lastquery:`timestamp$();usage:`timespan$();attributes:())
addserverattr:{[handle;servertype;attributes] `.gw.servers upsert (nextserverid[];handle;servertype;0b;1b;0i;0Np;0D;attributes)}
addserver:addserverattr[;;()!()]
setserverstate:{[serverh;use] 
 $[use;
   update inuse:use,lastquery:.z.p,querycount+1i from `.gw.servers where handle in serverh;
   update inuse:use,usage:usage+.z.p - lastquery from `.gw.servers where handle in serverh]}

// return a list of available servers
// override this function for different routing algorithms e.g. maybe only send to servers in the same datacentre, country etc.
// use the attributes as required
availableserverstable:{[excludeinuse]
 $[excludeinuse;
  select from servers where active, not inuse;
  select from `inuse xasc select serverid,handle,servertype,inuse from servers where active]}
availableservers:{[excludeinuse] exec handle!servertype from availableserverstable[excludeinuse]};

// join the queryqueue and client details together
queryandclients:{aj[`clienth`time;queryqueue;clients]}

// get the table of queries which can be run based on the available servers and those which are waiting
canberun:{
 // check if it's possible to run anything
 availServers:availableserverstable[1b];
 if[0=count avail:distinct exec servertype from availServers;
	:update required:(),available:(),handles:() from 0#0!queryqueue];
  availIDs:exec serverid from availServers;
 queue:$[eod;select from queryqueue where 1=count each distinct each{@[(exec serverid!servertype from .gw.servers)@;x;x]}servertype;queryqueue];
 select from 
  (update available:{$[11h=type z; z inter x; z where 0<count each z inter\: y]}[avail;availIDs] each required from
   (update required:(where each null each .gw.results[;1;;0])[queryid] from 
     (update required:servertype from 
      select from 0!queue where null returntime)
    where queryid in key .gw.results))
 where 0<count each raze each available}

// Manage client queries
addquerytimeout:{[query;servertype;queryattributes;join;postback;timeout] 
   `.gw.queryqueue upsert (nextqueryid[];.z.p;.z.w;query;servertype;queryattributes;join;postback;timeout;0Np;0Np;0b;0<count queryattributes)}
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
 serverid:first exec serverid from .gw.servers where active, handle=.z.w;
 if[queryid in key .gw.results; .[`.gw.results;(queryid;1;.gw.results[queryid;1;;0]?serverid;1);:;results]];
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
 if[null serverid:first exec serverid from .gw.servers where handle=serverh; :()];

 // get the list of effected query ids

 // 1) queries sent to this server but no reply back yet
 qids:where {[res;id] any (::)~/:res[1;where id=res[1;;0];1]}[;serverid] each results;
 // propagate an error back to each client
 sendclientreply[;.gw.errorprefix,"backend ",(string servertype)," server handling query closed the connection"] each qids;
 finishquery[qids;1b;serverh]; 

 // 2) queries partially run + waiting for this server
 activeServerIDs:exec serverid from .gw.servers where active, handle<>serverh;
 activeServerTypes:distinct exec servertype from .gw.servers where active, handle<>serverh;

 qids2:where {[res;id;aIDs;aTypes] 
	s:where (::)~/:res[1;;1]; 
	$[11h=type s; not all s in aTypes; not all any each s in\: aIDs] 
	}[;serverid;activeServerIDs;activeServerTypes] each results _ 0Ni;
 sendclientreply[;.gw.errorprefix,"backend ",(string servertype)," server for running query closed the connection"] each qids2;
 finishquery[qids2;1b;serverh]; 

 // 3) queries not yet run + waiting for this server
 qids3:exec queryid from .gw.queryqueue where null submittime, not `boolean${$[11h=type z; all z in x; all any each z in\: y]}[activeServerTypes;activeServerIDs] each servertype; 
 // propagate an error back to each client
 sendclientreply[;.gw.errorprefix,"backend ",(string servertype)," server for queued query closed the connection"] each qids3;
 finishquery[qids3;1b;serverh]; 

 // mark the server as inactive
 update handle:0Ni, active:0b from `.gw.servers where handle=serverh;

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




/- NEED TO FILTER ON PREFERENCES FIRST

/- initial common bit of functionality for filtering on servers
getserversinitial:{[req;att]

 if[0=count req; :([]serverid:enlist key att)];

 /- check if all servers report all the requirements - drop any that don't
 att:(where all each (key req) in/: key each att)#att;

 if[not count att; '"getservers: no servers report all requested attributes"];

 /- calculate where each of the requirements is in each of the attribute sets
 s:update serverid:key att from value req in'/: (key req)#/:att;

 /- calculate how many requirements are satisfied by each server
 /- the requirments satisfied is the minimum of each
 /- resort the table by this
 s:s idesc value min each sum each' `serverid xkey s;

 /- split the servers into groups - those with the same attributes are in the same group
 /- we only need to query one of these
 s:`serverid xkey 0!(key req) xgroup s;

 s}

/- given a dictionary of requirements and a list of attribute dictionaries
/- work out which servers we need to hit to satisfy each requirement
/- each requirement only has to be satisfied once, i.e. requirements are treated independently
getserversindependent:{[req;att;besteffort]

 if[0=count req; :([]serverid:enlist key att)];

 s:getserversinitial[req;att];

 /- we want to calculate which rows have not already been fully satisfied
 /- if the matched value in a row has already been matched, then it is useless
 filter:(value s)&not -1 _ (0b&(value s) enlist 0),maxs value s;

 /- work out whether the requirement is completely filled
 alldone:1+first where all each all each' maxs value s;

 if[(null alldone) and not besteffort;
        '"getserversindependent: cannot satisfy query as not all attributes can be matched"];

 /- use the filter to remove any rows which don't add value
 s:1!(0!s) w:where any each any each' filter;

 /- map each server id group to each of the attributes that it has available
 /- if you want overlaps, remove the &filter w from the end of this bit of code
 (key s)!{(key x)!(value x)@'where each y key x}[req]each value s&filter w}

/- build a cross product from a nested dictionary
buildcross:{(cross/){flip (enlist y)#x}[x] each key x}

/- given a dictionary of requirements and a list of attribute dictionaries
/- work out which servers we need to hit to satisfy each requirement
/- we want to satisfy the cross product of requirements - so each attribute has to be available with each other attribute
/- e.g. each symbol has to be availble within each specified date
getserverscross:{[req;att;besteffort]

 if[0=count req; :([]serverid:enlist key att)];

 s:getserversinitial[req;att];

 /- build the cross product of requirements
 reqcross:buildcross[req];

 /- calculate the cross product of data contributed by each source
 /- and drop it from the list of stuff that is required
 util:flip `remaining`found!flip ({[x;y;z] (y[0] except found; y[0] inter found:$[0=count y[0];y[0];buildcross x@'where each z])}[req]\)[(reqcross;());value s];

 /- check if everything is done
 if[(count last util`remaining) and not besteffort;
        '"getserverscross: cannot satisfy query as the cross product of all attributes can't be matched"];

 /- remove any rows which don't add value
 s:1!(0!s) w:where not 0=count each util`found;

 /- return the parameters which should be queried for
 (key s)!distinct each' flip each util[w]`found
 }

getserverids:{[att]
  if[99h<>type att;
	// its a list of servertypes e.g. `rdb`hdb
	servertype:att,();
	missing:servertype except exec distinct servertype from .gw.servers where active;
	if[count missing; '"not all of the requested server types are available; missing "," " sv string missing];
	:(exec serverid by servertype from .gw.servers where active)[servertype];
  ];

  // its a dictionary of attributes

  serverids:$[`servertype in key att; 
	raze getserveridstype[delete servertype from att] each (),att`servertype; 
	getserveridstype[att;`all]];

  if[all 0=count each serverids; '"no servers match requested attributes"];
  :serverids;
 }

getserveridstype:{[att;typ]
  // default values
  besteffort:1b;
  attype:`cross;

  servers:$[typ=`all;
		exec serverid!attributes from .gw.servers where active;
		exec serverid!attributes from .gw.servers where active, servertype=typ];

  if[`besteffort in key att;
	if[-1h=type att`besteffort; besteffort:att`besteffort];
	att:delete besteffort from att;
  ];
  if[`attributetype in key att;
	if[-11h=type att`attributetype; attype:att`attributetype];
	att:delete attributetype from att;
  ];

  res:$[attype=`independent; 
	getserversindependent[att;servers;besteffort];
	getserverscross[att;servers;besteffort]];

  serverids:first value flip $[99h=type res; key res; res];
  if[all 0=count each serverids; '"no servers match ",string[typ]," requested attributes"];
  :serverids;
 }

// execute an asynchronous query
asyncexecjpt:{[query;servertype;joinfunction;postback;timeout]
 /- if sync calls are allowed disable async calls to avoid query conflicts
 $[.gw.synccallsallowed;errStr:.gw.errorprefix,"synchronous calls are only allowed";
 [errStr:"";
 if[99h<>type servertype;
	// its a list of servertypes e.g. `rdb`hdb
	servertype,:();
	missing:(servertype,()) except exec distinct servertype from .gw.servers where active;
	if[count missing; errStr:.gw.errorprefix,"not all of the requested server types are available; missing "," " sv string missing];
	queryattributes:()!();
 ];
 if[99h=type servertype;
	// its a dictionary of attributes
	queryattributes:servertype;
	res:@[getserverids;queryattributes;{.gw.errorprefix,"getserverids: failed with error - ",x}];
	if[10h=type res; errStr:res];
	if[10h<>type res; if[0=count raze res; errStr:.gw.errorprefix,"no servers match given attributes"]];
	servertype:res;
 ]]];
 if[count errStr;
  @[neg .z.w;$[()~postback;errStr;$[-11h=type postback;enlist postback;postback],(enlist query),enlist errStr];()];
  :()];

 addquerytimeout[query;servertype;queryattributes;joinfunction;postback;timeout];
 runnextquery[];
 }

asyncexec:asyncexecjpt[;;raze;();0Wn]

// execute a synchronous query
syncexecj:{[query;servertype;joinfunction]
 if[not .gw.synccallsallowed; '`$"synchronous calls are not allowed"];
 // check if we have all the servers active
 serverids:getserverids[servertype];
 // check if gateway in eod reload phase
 if[checkeod[serverids]; '"unable to query multiple servers during eod reload"];
 // get the list of handles
 tab:availableserverstable[0b];
 handles:(exec serverid!handle from tab)first each (exec serverid from tab) inter/: serverids;
 start:.z.p;
 setserverstate[handles;1b];
 start:.z.p;
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
 if[not checkeod torun`servertype;
  torun:first torun;
  // if it isn't already in the result dict, add it
  if[not torun[`queryid] in key results;
   addemptyresult[torun`queryid;torun`clienth;torun`servertype]];
  // update the results dictionary and send off the queries
  // get the handles to run on
  avail:availableserverstable[1b];
  IDs:$[11h=type torun`available; 
	(exec first serverid by servertype from avail)[torun`available]; 
	first each (exec serverid from avail) inter/: torun`available];
  handles:avail[([]serverid:IDs);`handle];
  // update the results dictionary
  addservertoquery[torun`queryid;torun`available;IDs]; 
  // send off the queries
  sendquerytoserver[torun`queryid;torun`query;handles]]];
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

\d .

// functions called by end-of-day processes

reloadstart:{
 .lg.o[`reload;"reload start called"];
 /- set eod variable to active/true
 .gw.seteod[1b];
 /- extract ids of queries not yet returned
 qids:exec queryid from .gw.queryqueue where 1<count each distinct each{@[(exec serverid!servertype from .gw.servers)@;x;x]}each servertype,null returntime;
 /- propagate a timeout error to each client
 if[count qids;.gw.sendclientreply[;.gw.errorprefix,"query did not return prior to eod reload"]each qids;.gw.finishquery[qids;1b;0Ni]];}

reloadend:{
 .lg.o[`reload;"reload end called"];
 /- set eod variable to false
 .gw.seteod[0b];
 /- retry connections - get updated attributes from servers and refresh servers tables
 update attributes:@[;(`.proc.getattributes;`);()!()]each w from`.servers.SERVERS;
 update attributes:(exec w!attributes from .servers.SERVERS)handle from `.gw.servers;
 /- flush any async queries held during reload phase
 .gw.runnextquery[];}

// Add calls to the timer
if[@[value;`.timer.enabled;0b];
 .timer.repeat[.z.p;0Wp;0D00:05;(`.gw.removequeries;.gw.querykeeptime);"Remove old queries from the query queue"];
 .timer.repeat[.z.p;0Wp;0D00:00:05;(`.gw.checktimeout;`);"Timeout queries which have been waiting too long"]];

// add in some api details 
.api.add[`.gw.asyncexecjpt;1b;"Execute a function asynchronously.  The result is posted back to the client either directly down the socket (in which case the client must block and wait for the result - deferred synchronous) or wrapped in the postback function";"[(string | mixed list): the query to execute; symbol(list): the list of servers to query against; lambda: the function used to join the resulting data; symbol or lambda: postback;timespan: query timeout]";"The result of the query either directly or through the postback function"]
.api.add[`.gw.asyncexec;1b;"Execute a function asynchronously.  The result is posted back to the client directly down the socket. The client must block and wait for the result - deferred synchronous.  Equivalent to .gw.asyncexecjpt with join function of raze, no postback and no timeout";"[(string | mixed list): the query to execute; symbol(list): the list of servers to query against]";"The result of the query"]
.api.add[`.gw.syncexecj;1b;"Execute a function asynchronously, join the results with the specified join function";"[(string | mixed list): the query to execute; symbol(list): the list of servers to query against; lambda: the function used to join the resulting data]";"The result of the query"];
.api.add[`.gw.syncexec;1b;"Execute a function asynchronously, use raze to join the results";"[(string | mixed list): the query to execute; symbol(list): the list of servers to query against]";"The result of the query"];
.api.add[`.gw.getqueue;1b;"Return the current queryqueue with status";"[]";"table: the current queryqueue with either pending or running status"];

// make connections to processes as they appear in the .servers.SERVERS table
.servers.connectcustom:{[f;connectiontab]
  .gw.addserversfromconnectiontable[.servers.CONNECTIONS];
  f@connectiontab
 }@[value;`.servers.connectcustom;{{[x]}}]


/

// have 3 hdbs and 1 rdb, then run on gw to updte attributes in .gw.servers
update {x[`tables]:distinct x[`tables],`data;x} each attributes from `.gw.servers where servertype=`hdb
update attributes:{[x;d] update date:d from x}'[attributes;2 cut -1+.z.d-til 6] from `.gw.servers where servertype=`hdb


h:hopen 5180  // handle to gw

h".gw.synccallsallowed:1b"

// rdb only
neg[h](`.gw.asyncexec;"`$last .z.x";`rdb);h[]
neg[h](`.gw.asyncexec;"`$last .z.x";enlist[`tables]!enlist enlist`trade);h[]
neg[h](`.gw.asyncexec;"`$last .z.x";enlist[`date]!enlist enlist .z.d);h[]
neg[h](`.gw.asyncexec;"`$last .z.x";`tables`servertype!(enlist`logmsg;`rdb));h[]
h(`.gw.syncexec;"`$last .z.x";`rdb)
h(`.gw.syncexec;"`$last .z.x";enlist[`tables]!enlist enlist`trade)
h(`.gw.syncexec;"`$last .z.x";`tables`servertype!(enlist`logmsg;`rdb))

// hdb only
neg[h](`.gw.asyncexec;"`$last .z.x";`hdb);h[]
neg[h](`.gw.asyncexec;"`$last .z.x";enlist[`tables]!enlist enlist`data);h[]
neg[h](`.gw.asyncexec;"`$last .z.x";enlist[`date]!enlist enlist .z.d-1);h[]
neg[h](`.gw.asyncexec;"`$last .z.x";`tables`date!(enlist`data;enlist .z.d-3));h[]
neg[h](`.gw.asyncexec;"`$last .z.x";`tables`servertype`date!(enlist`data;`hdb;enlist .z.d-5));h[]
h(`.gw.syncexec;"`$last .z.x";`hdb)
h(`.gw.syncexec;"`$last .z.x";enlist[`tables]!enlist enlist`data)
h(`.gw.syncexec;"`$last .z.x";enlist[`date]!enlist enlist .z.d-1)
h(`.gw.syncexec;"`$last .z.x";`tables`date!(enlist`data;enlist .z.d-3))
h(`.gw.syncexec;"`$last .z.x";`tables`servertype`date!(enlist`data;`hdb;enlist .z.d-5))

// rdb + hdb
neg[h](`.gw.asyncexec;"`$last .z.x";`rdb`hdb);h[]
neg[h](`.gw.asyncexec;"`$last .z.x";enlist[`servertype]!enlist`rdb`hdb);h[]
neg[h](`.gw.asyncexec;"`$last .z.x";`tables`servertype!(enlist`logmsg;`rdb`hdb));h[]
neg[h](`.gw.asyncexec;"`$last .z.x";enlist[`date]!enlist .z.d-til 7);h[]
h(`.gw.syncexec;"`$last .z.x";`rdb`hdb)
h(`.gw.syncexec;"`$last .z.x";enlist[`servertype]!enlist`rdb`hdb)
h(`.gw.syncexec;"`$last .z.x";`tables`servertype!(enlist`logmsg;`rdb`hdb))
h(`.gw.syncexec;"`$last .z.x";enlist[`date]!enlist .z.d-til 7)

// errors
neg[h](`.gw.asyncexec;"`$last .z.x";enlist[`tables]!enlist enlist`logmsgXXX);h[]
neg[h](`.gw.asyncexec;"`$last .z.x";`tables`servertype!(enlist`data;`rdb`hdb));h[]
neg[h](`.gw.asyncexec;"`$last .z.x";update besteffort:0b from enlist[`date]!enlist .z.d-til 10);h[]
neg[h](`.gw.asyncexecjpt;(`.q.system;"sleep 10");enlist[`servertype]!enlist`rdb`hdb;raze;();0D00:00:03);h[]
h(`.gw.syncexec;"`$last .z.x";enlist[`tables]!enlist enlist`logmsgXXX)
h(`.gw.syncexec;"`$last .z.x";`tables`servertype!(enlist`data;`rdb`hdb))


