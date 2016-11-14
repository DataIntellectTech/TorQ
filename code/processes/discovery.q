// Discovery service to allow lookup of clients
// Discovery service attempts to connect to each process at start up
// after that, each process should attempt to connect back to the discovery service
// Discovery service only gives out information on registered services - it doesn't really need to have connected to them
// The reason for having a connection is just to get the attributes.

// Make sure all connections are created as standard sockets
.servers.SOCKETTYPE:enlist[`]!enlist `

// initialise connections
.servers.startup[]

// subscriptions - handles to list of required proc types
subs:(`int$())!()

register:{
	// add the new handle
	.servers.addw .z.w;
	// If there already was an entry for the same host:port as the supplied handle, close it and delete the entry
	// this is to handle the case where the discovery service connects out, then the process connects back in on a timer
	if[count toclose:exec i from .servers.SERVERS where not w=.z.w,hpup in exec hpup from .servers.SERVERS where w=.z.w;
		.servers.removerows toclose];
	// publish the updates
	new:select proctype,procname,hpup,attributes from .servers.SERVERS where w=.z.w;
	(neg ((where ((first new`proctype) in/: subs) or subs~\:enlist`ALL) inter key .z.W) except .z.w)@\:(`.servers.procupdate;new);
	} 


// get a list of services
getservices:{[proctypes;subscribe] 
	.servers.cleanup[];
	if[subscribe; subs[.z.w]:proctypes,()]; 
	distinct select procname,proctype,hpup,attributes from .servers.SERVERS where proctype in ?[(proctypes~`ALL) or proctypes~enlist`ALL;proctype;proctypes],not proctype=`discovery}

// add each handle
@[.servers.addw;;{.lg.e[`discovery;x]}] each exec w from .servers.SERVERS where .dotz.liveh w, not hpup in (exec hpup from .servers.nontorqprocesstab);

// try to make each server connect back in 
/ (neg exec w from .servers.SERVERS where .dotz.liveh w)@\:"@[value;(`.servers.autodiscovery;`);()]";
(neg exec w from .servers.SERVERS where .dotz.liveh w,not hpup in exec hpup from .servers.nontorqprocesstab)@\:(`.servers.autodiscovery;`);

// modify .z.pc - drop items out of the subscription dictionary
.z.pc:{subs::(enlist y) _ subs; x@y}@[value;`.z.pc;{;}]
