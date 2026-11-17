startorstopproc:{[startorstop;procname;processcsv] 
	.proc.sys getenv[`TORQHOME],"/torq.sh ",startorstop," ",procname," -csv ",processcsv
	};

// The pids of this user's processes whose command line matches the pattern (the user by id, as USER is not always
// set). The process is found by TorQ's own arguments, not by the name of its executable, which is not always q (a
// wrapper script, or a binary under another name). The first character goes in brackets so that the pattern cannot
// match this pgrep command itself
procpids:{[pattern] @[system;"pgrep -u $(id -u) -f \"[",(1#pattern),"]",(1_pattern),"\"";()]};

deadproccheck:{[proctype;procname]
	0=count procpids "stackid ",getenv[`KDBBASEPORT]," -proctype ",proctype," -procname ",procname
	};

// Kill process dead with -9
kill9proc:{[proc] system "kill -9 "," " sv procpids "procname ",proc};

// Returns boolean true if process is alive
isalive:{[proc] 0<count procpids "procname ",proc};

// Have slightly more fluid handle opening mechanic - update: force it to open a new handle each time
gethandle:{[name] 
	.z.pc exec first w from .servers.SERVERS where procname=name;
	exec first w from .servers.getservers[`procname;name;()!();1b;1b]
	};
