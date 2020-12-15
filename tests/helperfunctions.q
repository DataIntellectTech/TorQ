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
	.z.pc exec first w from .servers.SERVERS where procname=name;
	exec first w from .servers.getservers[`procname;name;()!();1b;1b]
	};
