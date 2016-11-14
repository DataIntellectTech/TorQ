killhandle:{@[x:neg x;"exit 0";()]; @[x;[];()]}

// make the connections
.servers.startup[]

// if killnames is on the commandline, then only kill the servers with the specific names
// need to make sure that for each name we retrieve the type that the servers is a part of as well
$[`killnames in key .proc.params;
	[names:"S"$'.proc.params[`killnames];
	 .lg.o[`kill;"killing processes with names ",-3!names];
	 s:.servers.getservers[`procname;"S"$'.proc.params[`killnames];()!();1b;0b]];	
	 s:.servers.getservers[`proctype;.servers.CONNECTIONS;()!();1b;0b]];

// exit if no connections
if[0=count s; .lg.o[`kill;"Failed to find any valid connections"]; exit 0]

// kill each connection
{.lg.o[`kill;"Sending kill command to ",(string x`proctype)," process with name ",(string x`procname)," at hp ",string x`hpup];
	killhandle x`w;}each s;

.lg.o[`kill;"Exiting"]
exit 0
