startorstopproc:{[startorstop;procname;processcsv] 
	.proc.sys getenv[`TORQHOME],"/torq.sh ",startorstop," ",procname," -csv ",processcsv
	};

deadproccheck:{[proctype;procname]
	/ pairs are of the form "<PID> ssh" for 'PID TTY...' part of pgrep, and "<PID> q" if process is running
	pidnamepairs:.proc.sys "pgrep -lf \"stackid ",getenv[`KDBBASEPORT]," -proctype ",proctype," -procname ",procname,"\"";
	not "q" in last each pidnamepairs
	};

opentorqhandle:{[port]
	hopen `$"::",port,":admin:admin"	
	};

// Kill process dead with -9
kill9proc:{[proc] a:"q" in' b:@[system;"pgrep -lf ",proc;`down];system "kill -9 ",first " " vs first b where a};

// Returns boolean true if process is alive
isalive:{[proc] any "q" in' @[system;"pgrep -lf ",proc;`down]};

// Have slightly more fluid handle opening mechanic
gethandle:{[name] exec first w from .servers.getservers[`procname;name;()!();1b;1b]};