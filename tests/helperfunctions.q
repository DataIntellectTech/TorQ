startorstopproc:{[startorstop;procname;processcsv] 
	.proc.sys getenv[`TORQHOME],"/torq.sh ",startorstop," ",procname," -csv ",processcsv
	};

deadproccheck:{[proctype;procname]
	/ pairs are of the form "<PID> ssh" for 'PID TTY...' part of pgrep, and "<PID> q" if process is running
	pidnamepairs:.proc.sys "pgrep -lf \"stackid ",getenv[`KDBBASEPORT]," -proctype ",proctype," -procname ",procname,"\"";
	not "q" in last each pidnamepairs
	};

// Kill process dead with -9
kill9proc:{[proc] a:"q" in' b:@[system;"pgrep -lf ",proc," -u $USER";" "];system "kill -9 ",first " " vs first b where a};

// Returns boolean true if process is alive
isalive:{[proc] any "q" in' @[system;"pgrep -lf ",proc," -u $USER";" "]};

// Have slightly more fluid handle opening mechanic - update: force it to open a new handle each time
gethandle:{[name] 
	.z.pc h:exec first w from .servers.SERVERS where procname=name;
	// close the old handle as well: .z.pc only marks it closed, and a process can run out of connections
	if[not null h;@[hclose;h;()]];
	exec first w from .servers.getservers[`procname;name;()!();1b;1b]
	};

// Wait up to 30 seconds for a process to accept a connection, and return its handle (null if it never did): a fixed
// sleep after starting several processes at once is not always long enough
waitforhandle:{[name] t:.z.p+0D00:00:30; while[(null h:gethandle name) and .z.p<t; system "sleep 0.5"]; h};

// Wait up to 30 seconds until a gateway has as many active connections to each server type as given (type!count)
waitforgateway:{[gwh;need] t:.z.p+0D00:00:30;
	while[(not all need<=0^(count each group gwh"exec servertype from .gw.servers where active")key need) and .z.p<t;
		system "sleep 0.5"];
	};
