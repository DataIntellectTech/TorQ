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
