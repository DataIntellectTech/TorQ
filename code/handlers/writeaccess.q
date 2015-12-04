// This is used to make data available in the process read only
// Uses reval to block the write access to connecting clients
// Reval is available in KDB+ 3.3 onwards
// If enabled on older KDB versions this will throw an error
// Write protection is only provided on string based messaging
// Http access is disabled

\d .readonly

enabled:@[value;`enabled;0b]				// whether read only is enabled

\d .

.lg.o[`readonly;"read only mode is ",("disabled";"enabled").readonly.enabled];
if[.readonly.enabled;
	// Check if the current KDB version supports blocking write access to clients
	if[3.3>.z.K;
		.lg.e[`readonly;"current KDB+ version ",(string .z.K),
		" does not support blocking write access,a minimum of KDB+ version 3.3 is required"]
		];		
	// Modify the sync message handler	
	.z.pg:{[x;y] $[10h=type y;reval(x;y); x y]}.z.pg;
	// Modify the async message handler	
	.z.ps:{[x;y] $[10h=type y;reval(x;y); x y]}.z.ps;	
	// Modify the websocket message handler	
	.z.ws:{[x;y] $[10h=type y;reval(x;y); x y]}.z.ws;	
	
	// Modify the http get message handler	
	.z.ph:{[x] .h.hn["403 Forbidden";`txt;"Forbidden"]};	
	// Modify the http post message handler	
	.z.pp:{[x] .h.hn["403 Forbidden";`txt;"Forbidden"]};	
	];
