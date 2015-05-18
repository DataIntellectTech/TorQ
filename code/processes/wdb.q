/-TorQ wdb process - based upon w.q 
/http://code.kx.com/wsvn/code/contrib/simon/tick/w.q
/-subscribes to tickerplant and appends data to disk after the in-memory table exceeds a specified number of rows
/-the row check is set on a timer - the interval may be specified by the user
/-at eod the on-disk data may be sorted and attributes applied as specified in the sort.csv file

\d .wdb
/- define default parameters
mode:@[value;`mode;`saveandsort];	/- the wdb process can operate in three modes
									/- 1. saveandsort 	- 	the process will subscribe for data,
									/-						periodically write data to disk and at EOD it will flush 
									/-						remaining data to disk before sorting it and informing
									/-						GWs, RDBs and HDBs etc...
									/- 2. save 			-	the process will subscribe for data,
									/- 						periodically write data to disk and at EOD it will flush 
									/-						remaining data to disk.  It will then inform it's respective
									/-						sort mode process to sort the data
									/- 3. sort			-	the process will wait to get a trigger from it's respective
									/-						save mode process.  When this is triggered it will sort the
									/- 						data on disk, apply attributes and the trigger a reload on the
									/-						rdb and hdb processes

hdbtypes:@[value;`hdbtypes;`hdb];                               /-list of hdb types to look for and call in hdb reload
rdbtypes:@[value;`rdbtypes;`rdb];                               /-list of rdb types to look for and call in rdb reload
gatewaytypes:@[value;`gatewaytypes;`gateway]			/-list of gateway types to inform at reload
tickerplanttypes:@[value;`tickerplanttypes;`tickerplant];       /-list of tickerplant types to try and make a connection to
tpconnsleepintv:@[value;`tpconnsleepintv;10];                   /-number of seconds between attempts to connect to the tp											
										
subtabs:@[value;`subtabs;`]                                     /-list of tables to subscribe for
subsyms:@[value;`subsyms;`]                                     /-list of syms to subscription to
upd:@[value;`upd;{insert}]                                      /-value of the upd function

ignorelist:@[value;`ignorelist;`heartbeat`logmsg]               /-list of tables to ignore
replay:@[value;`replay;1b]                                      /-replay the tickerplant log file
schema:@[value;`schema;1b]                                      /-retrieve schema from tickerplant
numrows:@[value;`numrows;1000]                                  /-default number of rows 
savedir:@[value;`savedir;`:temphdb]                             /-location to save wdb data
numtab:@[value;`numtab;`quote`trade!1000 500]                   /-specify number of rows per table
settimer:@[value;`settimer;0D00:00:10]                          /-set timer interval for row check 

partitiontype:@[value;`partitiontype;`date]                                         /-set type of partition (defaults to `date)
gmttime:@[value;`gmttime;1b];                                                       /-define whether the process is on gmttime or not
getpartition:@[value;`getpartition;{{(`date^partitiontype)$(.z.d;.z.D)gmttime}}];	/-function to determine the partition value

reloadorder:@[value;`reloadorder;`hdb`rdb]                      /-order to reload hdbs and rdbs
hdbdir:@[value;`hdbdir;`:hdb]                                   /-move wdb database to different location
sortcsv:@[value;`sortcsv;`:config/sort.csv]                     /-location of csv file
permitreload:@[value;`permitreload;1b]                          /-enable reload of hdbs/rdbs
compression:@[value;`compression;()];                           /-specify the compress level, empty list if no required

gc:@[value;`gc;1b]                                              /-garbage collect at appropriate points (after each table save and after sorting data)

eodwaittime:@[value;`eodwaittime;0D00:00:10.000]		/- length of time to wait for async callbacks to complete at eod

/ - settings for the common save code (see code/common/save.q)
.save.savedownmanipulation:@[value;`savedownmanipulation;()!()]	/-a dict of table!function used to manipulate tables at EOD save
.save.postreplay:@[value;`postreplay;{{[d;p] }}]			    /-post EOD function, invoked after all the tables have been written down

/ - end of default parameters

/- define the save and sort flags
saveenabled: any `save`saveandsort in mode;
sortenabled: any `sort`saveandsort in mode;

/ - log which modes are enabled
switch: string `off`on;
.lg.o[`savemode;"save mode is ",switch[saveenabled]];
.lg.o[`sortmode;"sort mode is ",switch[sortenabled]];

/ - check to ensure that the process can do one of save or sort
if[not any saveenabled,sortenabled; .lg.e[`init;"process mode not configured correctly.  Mode should be one of the following: save, sort or saveandsort"]];

/- function to return a list of tables that the wdb process has been configured to deal within
tablelist:{[] tables[`.] except ignorelist};

/- extract user defined row counts	
maxrows:{[tabname] numrows^numtab[tabname]}

/- if row count satisfied, save data to disk, then delete from memory
savetables:{[dir;pt;forcesave;tabname]
	/- check row count
	/- forcesave will write flush the data to disk irrespective of counts
	if[forcesave or maxrows[tabname] < arows: count value tabname;
	.lg.o[`rowcheck;"the ",(string tabname)," table consists of ", (string arows), " rows"];
	/- upsert data to partition
	.lg.o[`save;"saving ",(string tabname)," data to partition ", string pt];
	.[
		upsert;
		(` sv .Q.par[dir;pt;tabname],`;.Q.en[hdbdir;0!.save.manipulate[tabname;`. tabname]]);
		{[e] .lg.e[`savetables;"Failed to save table to disk : ",e];'e}
	];
	/- empty the table
	.lg.o[`delete;"deleting ",(string tabname)," data from in-memory table"];
	@[`.;tabname;0#];
	/- run a garbage collection (if enabled)
	if[gc;.gc.run[]];
	]};

savetodisk:{[] savetables[savedir;getpartition[];0b;] each tablelist[]}

/- eod - flush remaining data to disk
endofday:{[pt]
	.lg.o[`eod;"end of day message received - ",spt:string pt];
	/ - if save mode is enabled then flush all data to disk
	if[saveenabled;
		endofdaysave[savedir;pt];
		/ - if sort mode enable call endofdaysort within the process,else inform the sort and reload process to do it
		$[sortenabled;endofdaysort;informsortandreload] . (savedir;pt;tablelist[])];
	.lg.o[`eod;"end of day is now complete"];
	}
	
endofdaysave:{[dir;pt]
	/- save remaining table rows to disk
	.lg.o[`save;"saving the ",(raze (string tl:tablelist[]),'" "),"table(s) to disk"];
	savetables[dir;pt;1b;] each tl;
	.lg.o[`savefinish;"finished saving data to disk"];
	};

/- add entries to dictionary of callbacks. if timeout has expired or d now contains all expected rows then it releases each waiting process
handler:{
	.wdb.d[.z.w]:x;
	if[(.proc.cp[]>.wdb.timeouttime) or (count[.wdb.d]=.wdb.countreload);
		.lg.o[`handler;"releasing processes"];
		.wdb.flushend[];
		.wdb.d:()!()];
	}

/- evaluate contents of d dictionary asynchronously
/- notify the gateway that we are done
flushend:{
	if[not @[value;`.wdb.reloadcomplete;0b];
	 @[{neg[x]"";neg[x][]};;()] each key d;
	 informgateway"reloadend[]";
	 .lg.o[`sort;"end of day sort is now complete"];
	 .wdb.reloadcomplete:1b];
	}

/- initialise d
d:()!()

endofdaysort:{[dir;pt;tablist]
	/-sort permitted tables in database
	/- sort the table and garbage collect (if enabled)
	.lg.o[`sort;"starting to sort data"];
	{[x] .sort.sorttab[x];if[gc;.gc.run[]]} each tablist,'.Q.par[dir;pt;] each tablist;
	.lg.o[`sort;"finished sorting data"];
	/-move data into hdb
	.lg.o[`mvtohdb;"Moving partition from the temp wdb ",(dw:-1 _ string .Q.par[dir;pt;`])," directory to the hdb directory ",hw:-1 _ string .Q.par[hdbdir;`;`]];
	.[.os.ren;(dw;hw);{.lg.e[`mvtohdb;"Failed to move data from wdb ",x," to hdb directory ",y," : ",z]}[dw;hw]];
	/-call the posteod function
	.save.postreplay[hdbdir;pt];

	if[permitreload; 
		.wdb.reloadcomplete:0b;
		/-inform gateway of reload start
		informgateway["reloadstart[]"];
		getprocs[;pt] each reloadorder;
		if[eodwaittime>0;
		.timer.one[.wdb.timeouttime:.proc.cp[]+.wdb.eodwaittime;(value;".wdb.flushend[]");"release all hdbs and rdbs as timer has expired";0b];
		]];
	};

/-function to send reload message to rdbs/hdbs
reloadproc:{[h;d;ptype]
	.wdb.countreload:count[raze .servers.getservers[`proctype;;()!();1b;0b]each reloadorder];
	$[eodwaittime>0;
		{[x;y;ptype].[{neg[y]@x};(x;y);{[ptype;x].lg.e[`reloadproc;"failed to reload the ",string[ptype]];'x}[ptype]]}[({@[`. `reload;x;()]; (neg .z.w)(`.wdb.handler;1b); .z.w[]};d);h;ptype];
		@[h;(`reload;d);{[ptype;e] .lg.e[`reloadproc;"failed to reload the ",string[ptype],".  The error was : ",e][ptype]}];
	];
	.lg.o[`reload;"the ",string[ptype]," has been successfully reloaded"];
	}

/-function to discover rdbs/hdbs and attempt to reconnect	
getprocs:{[x;y]
	a:exec (w!x) from .servers.getservers[`proctype;x;()!();1b;0b];
	/-exit if no valid handle
	if[0=count a; .lg.e[`connection;"no connection to the ",(string x)," could be established... failed to reload ",string x];:()];
	.lg.o[`connection;"connection to the ", (string x)," has been located"];
	/-send message along each handle a
	reloadproc[;y;value a] each key a;
	}

/-function to send messages to gateway	
informgateway:{[message]
  	.lg.o[`informgateway;"sending message to gatway(s)"];
	$[count gateways:.servers.getservers[`proctype;gatewaytypes;()!();1b;0b];
	   [
		   {.[@;(y;x);{.lg.e[`informgateway;"unable to run command on gateway"];'x}]}[message;] each exec w from gateways;
		   .lg.o[`informgateway;"the message - ", message, " was sent to the gateways"]
	   ];
	   .lg.e[`informgateway;"can't connect to the gateway - no gateway detected"]]
	}
	
/- function to call that will cause sort & reload process to sort data and reload rdb and hdbs
informsortandreload:{[dir;pt;tablist]
	.lg.o[`informsortandreload;"attempting to contact sort process to initiate data sort"];
	$[count sortprocs:.servers.getservers[`proctype;`sort;()!();1b;0b];
		{.[{neg[y]@x;neg[y][]};(x;y);{.lg.e[`informsortandreload;"unable to run command on sort and reload process"];'x}]}[(`.wdb.endofdaysort;dir;pt;tablist);] each exec w from sortprocs;
		[.lg.e[`informsortandreload;"can't connect to the sortandreload - no sortandreload process detected"];
		 // try to run the sort locally
		 endofdaysort[dir;pt;tablist]]];
	};

/-function to set the timer for the save to disk function	
starttimer:{[]
	$[@[value;`.timer.enabled;0b];
		[.lg.o[`init;"adding the wdb save to disk function to the timer"];
		/-add .wdb.savetodisk function to TorQ timer 
		.timer.repeat[.proc.cp[];0Wp;settimer;(`.wdb.savetodisk;`);"save wdb data to disk"];
		.lg.o[`init;"the timer has been set to ", string settimer]];
		/-if timer not enabled, prompt user to enable it
		.lg.e[`init;"the timer has not been enabled - please enable the timer to run the wdb"]];
	}

/-function to subscribe to tickerplant	
subscribe:{[]
	s:.sub.getsubscriptionhandles[tickerplanttypes;();()!()];
	if[count s;
		.lg.o[`subscribe;"tickerplant found - subscribing to ", string (subproc: first s)`procname];
		.sub.subscribe[subtabs;subsyms;schema;replay;subproc]];}

/- will check on each upd to determine where data should be flushed to disk (if max row limit has been exceeded)
replayupd:{[f;t;d]
	/- execute the supplied function        
        f . (t;d);

	/ - if the data count is great than the threshold, then flush data to disk
	if[(rpc:count[value t]) > lmt:maxrows[t];
		.lg.o[`replayupd;"row limit (",string[lmt],") exceeded for ",string[t],". Table count is : ",string[rpc],". Flushing table to disk..."];
		savetables[savedir;getpartition[];0b;t]]
	}[upd];

/-function to initialise the wdb	
startup:{[] 
	.lg.o[`init;"searching for servers"];
	.servers.startup[];
	.lg.o[`init;"the partition has been set to type: ", string partitiontype];
	if[saveenabled;
		/- subscribe to tickerplant
		subscribe[];
		/-check if the tickerplant has connected, block the process until a connection is established
		while[notpconnected[];
			/-while no connected make the process sleep for X seconds and then run the subscribe function again
			.os.sleep[tpconnsleepintv];
			/-run the servers startup code again (to make connection to discovery)
			.servers.startup[];
			subscribe[]];		
		/- set compression level
		if[ 3= count compression;
			.lg.o[`compression;"setting compression level to (",(";" sv string compression),")"];
			.z.zd:compression;
			.lg.o[`compression;".z.zd has been set to (",(";" sv string .z.zd),")"]]];
	/- get the attributes csv file
  	/- even if running with a sort process should read this file in to cope with backups
	.sort.getsortcsv[sortcsv];
	}
	
/ - if there is data in the wdb directory for the partition, if there is remove it before replay
/ - is only for wdb processes that are saving data to disk
clearwdbdata:{[] 
	$[saveenabled and not () ~ key wdbpart:.Q.par[savedir;getpartition[];`];
		[.lg.o[`deletewdbdata;"removing wdb data (",(delstrg:1_string wdbpart),") prior to log replay"];
		@[.os.deldir;delstrg;{[e] .lg.e[`deletewdbdata;"Failed to delete existing wdb data.  Error was : ",e];'e }];
		.lg.o[`deletewdbdata;"finished removing wdb data prior to log replay"];
		];
		.lg.o[`deletewdbdata;"no directory found at ",1_string wdbpart]		
	];
	};
	
/ - function to check that the tickerplant is connected and subscription has been setup
notpconnected:{[]
	0 = count select from .sub.SUBSCRIPTIONS where proctype in .wdb.tickerplanttypes, active}


\d .

/- make sure to request connections for all the correct types
.servers.CONNECTIONS:(distinct .servers.CONNECTIONS,.wdb.hdbtypes,.wdb.rdbtypes,.wdb.gatewaytypes,.wdb.tickerplanttypes) except `

/- setting the upd and .u.end functions as the .wdb versions
.u.end:.wdb.endofday;
/- set the replay upd 
.lg.o[`init;"setting the log replay upd function"];
upd:.wdb.replayupd;
/ - clear any wdb data in the current partition
.wdb.clearwdbdata[];
/- initialise the wdb process
.wdb.startup[];
/ - start the timer
if[.wdb.saveenabled;.wdb.starttimer[]];

/- use the regular up after log replay
upd:.wdb.upd
