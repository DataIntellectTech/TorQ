/ log external (.z.p* & .z.exit) usage of a kdb+ session

// based on logusage.q from code.kx
// http://code.kx.com/wsvn/code/contrib/simon/dotz/
// Modifications : 
// usage table is stored in memory
// Data is written to file as ASCII text
// Added a new LEVEL - LEVEL 0 = nothing; 1=errors only; 2 = + open and queries; 3 = log queries before execution also

\d .usage

// table to store usage info
usage:@[value;`usage;([]time:`timestamp$();id:`long$();timer:`timespan$();zcmd:`symbol$();status:`char$();a:`int$();u:`symbol$();w:`int$();cmd:();mem:();sz:`long$();error:())]

// Check if the process has been initialised correctly
if[not @[value;`.proc.loaded;0b]; '"environment is not initialised correctly to load this script"]

// Flags and variables
enabled:@[value;`enabled;1b]                            // whether logging is enabled
logtodisk:@[value;`logtodisk;1b]			// whether to log to disk or not
logtomemory:@[value;`logtomemory;1b]			// write query logs to memory
ignore:@[value;`ignore;1b]				// check the ignore list for functions to ignore
ignorelist:@[value;`ignorelist;(`upd;"upd")]		// the list of functions to ignore
flushtime:@[value;`flushtime;0D03]			// default value for how long to persist the in-memory logs
suppressalias:@[value;`suppressalias;0b]		// whether to suppress the log file alias creation
logtimestamp:@[value;`logtimestamp;{[x] {[].z.d}}]	// function to generate the log file timestamp suffix
logroll:@[value;`logroll;1b]				// whether to automatically roll the log file
LEVEL:@[value;`LEVEL;3]					// Log level

id:@[value;`id;0j]
nextid:{:id+::1}

// A handle to the log file
logh:@[value;`logh;0]

// write a query log message
write:{
	if[logtodisk;@[neg logh;format x;()]];
	if[logtomemory; `.usage.usage upsert x];
	ext[x]}

// extension function to extend the logging e.g. publish the log message
ext:{[x]}

// format the string to be written to the file
format:{"|" sv -3!'x}

// flush out some of the in-memory stats
flushusage:{[flushtime] delete from `.usage.usage where time<.z.p - flushtime;}

createlog:{[logdir;logname;timestamp;suppressalias]
	basename:"usage_",(string logname),"_",(string timestamp),".log";
	// Close the current log handle if there is one 
	if[logh; @[hclose;logh;()]];
	// Open the file
	.lg.o[`usage;"creating usage log file ",lf:logdir,"/",basename];
	logh::hopen hsym`$lf;
	// Create an alias
	if[not suppressalias;
		.proc.createalias[logdir;basename;"usage_",(string logname),".log"]]; 
	}

// read in a log file 
readlog:{[file]
	@[{update "J"$'" " vs' mem from flip (cols .usage.usage)!("PJNSCISI**JS";"|")0:x};hsym`$file;{'"failed to read log file : ",x}]}

// roll the logs
// inmemorypersist = the number 
rolllog:{[logdir;logname;timestamp;suppressalias;persisttime]
	if[logtodisk; createlog[logdir;logname;timestamp;suppressalias]];
	flushusage[persisttime]}

rolllogauto:{rolllog[getenv`KDBLOG;.proc.procname;logtimestamp[];.usage.suppressalias;.usage.flushtime]}

// Get the memory info - we don't want to log the physical memory each time
meminfo:{5#system"w"}

logDirect:{[id;zcmd;endp;result;arg;startp] / log complete action
    if[LEVEL>1;write(startp;id;endp-startp;zcmd;"c";.z.a;.z.u;.z.w;.dotz.txtC[zcmd;arg];meminfo[];0Nj;"")];result}

logBefore:{[id;zcmd;arg;startp] / log non-time info before execution
    if[LEVEL>2;write(startp;id;0Nn;zcmd;"b";.z.a;.z.u;.z.w;.dotz.txtC[zcmd;arg];meminfo[];0Nj;"")];}

logAfter:{[id;zcmd;endp;result;arg;startp] / fill in time info after execution
    if[LEVEL>1;write(endp;id;endp-startp;zcmd;"c";.z.a;.z.u;.z.w;.dotz.txtC[zcmd;arg];meminfo[];-22!result;"")];result}
	
logError:{[id;zcmd;endp;arg;startp;error] / fill in error info
    if[LEVEL>0;write(endp;id;endp-startp;zcmd;"e";.z.a;.z.u;.z.w;.dotz.txtC[zcmd;arg];meminfo[];0Nj;error)];'error}
	
p0:{[x;y;z;a]logDirect[nextid[];`pw;.z.p;y[z;a];(z;"***");.z.p]}
p1:{logDirect[nextid[];x;.z.p;y z;z;.z.p]}
p2:{id:nextid[];logBefore[id;x;z;.z.p];logAfter[id;x;.z.p;@[y;z;logError[id;x;.z.p;z;start;]];z;start:.z.p]}
// Added to allow certain functions to be excluded from logging
p3:{if[ignore; if[0h=type z;if[any first[z]~/:ignorelist; :y@z]]]; p2[x;y;z]}

if[enabled;
	// Create a log file
	rolllogauto[];

	// If the timer is enabled, and logrolling is set to true, try to log the roll file on a daily basis
	if[logroll;
        	$[@[value;`.timer.enabled;0b];
                	[.lg.o[`init;"adding timer function to roll usage logs on a daily schedule starting at ",string `timestamp$(.z.d+1)+00:00];
                 	.timer.rep[`timestamp$.z.d+00:00;0Wp;1D;(`.usage.rolllogauto;`);0h;"roll query logs";1b]];
                	.lg.e[`init;".usage.logroll is set to true, but timer functionality is not loaded - cannot roll usage logs"]]];

	if[flushtime>0;
		$[@[value;`.timer.enabled;0b];
                	[.lg.o[`init;"adding timer function to flush in-memory usage logs on 30 minute schedule"];
                 	.timer.repeat[.z.p;0Wp;0D00:30;(`.usage.flushusage;flushtime);"flush in memory usage logs"]];
                	.lg.e[`init;".usage.flushtime is greater than 0, but timer functionality is not loaded - cannot flush in memory tables"]]];

	.z.pw:p0[`pw;.z.pw;;];
	.z.po:p1[`po;.z.po;];.z.pc:p1[`pc;.z.pc;];
	.z.ws:p2[`ws;.z.ws;];.z.exit:p2[`exit;.z.exit;];
	.z.pg:p2[`pg;.z.pg;];.z.pi:p2[`pi;.z.pi;];
	.z.ph:p2[`ph;.z.ph;];.z.pp:p2[`pp;.z.pp;];
	.z.ps:p3[`ps;.z.ps;];]
