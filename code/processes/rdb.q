/TorQ rdb process - based on r.q from kdb+tick
/http://code.kx.com/wsvn/code/kx/kdb+tick/
/-changes added 
/-Can specify the hdb directory rather than relying on the tickerplant

/-default parameters
\d .rdb

hdbtypes:@[value;`hdbtypes;`hdb];                           //list of hdb types to look for and call in hdb reload
hdbnames:@[value;`hdbnames;()];                             //list of hdb names to search for and call in hdb reload
tickerplanttypes:@[value;`tickerplanttypes;`tickerplant];   //list of tickerplant types to try and make a connection to
gatewaytypes:@[value;`gatewaytypes;`gateway]                //list of gateway types

replaylog:@[value;`replaylog;1b];                           //replay the tickerplant log file
schema:@[value;`schema;1b];                                 //retrieve the schema from the tickerplant
subscribeto:@[value;`subscribeto;`];                        //a list of tables to subscribe to, default (`) means all tables
ignorelist:@[value;`ignorelist;`heartbeat`logmsg];          //list of tables to ignore when saving to disk
subscribesyms:@[value;`subscribesyms;`];                    //a list of syms to subscribe for, (`) means all syms
tpconnsleepintv:@[value;`tpconnsleepintv;10];               //number of seconds between attempts to connect to the tp											

onlyclearsaved:@[value;`onlyclearsaved;0b];                 //if true, eod writedown will only clear tables which have been successfully saved to disk
savetables:@[value;`savetables;1b];                         //if true tables will be saved at end of day, if false tables wil not be saved, only wiped
gc:@[value;`gc;1b];                                         //if true .Q.gc will be called after each writedown - tradeoff: latency vs memory usage
upd:@[value;`upd;{insert}];                                 //value of upd
hdbdir:@[value;`hdbdir;`:hdb];                              //the location of the hdb directory
sortcsv:@[value;`sortcsv;`:config/sort.csv]                 //location of csv file

reloadenabled:@[value;`reloadenabled;0b];                   //if true, the RDB will not save when .u.end is called but 
                                                            //will clear it's data using reload function (called by the WDB)
parvaluesrc:@[value;`parvaluesrc;`log];                     //where to source the rdb partition value, can be log (from tp log file name), 
                                                            //tab (from the the first value in the time column of the table that is subscribed for) 
                                                            //anything else will return a null date which is will be filled by pardefault									
pardefault:@[value;`pardefault;.z.D];                       //if the src defined in parvaluesrc returns null, use this default date instead 
tpcheckcycles:@[value;`tpcheckcycles;0W];                   //specify the number of times the process will check for an available tickerplant

/ - if the timer is not enabled, then exit with error
if[not .timer.enabled;.lg.e[`rdbinit;"the timer must be enabled to run the rdb process"]];

/ - settings for the common save code (see code/common/save.q)
.save.savedownmanipulation:@[value;`savedownmanipulation;()!()]     //a dict of table!function used to manipulate tables at EOD save
.save.postreplay:@[value;`postreplay;{{[d;p] }}]                    //post EOD function, invoked after all the tables have been written down

/- end of default parameters

cleartable:{[t].lg.o[`writedown;"clearing table ",string t]; @[`.;t;0#]}

savetable:{[d;p;t]
	/-flag to indicate if save was successful - must be set to true first incase .rdb.savetables is set to false
	c:1b;
	/-save the tables 
	if[savetables;
		@[.sort.sorttab;t;{[t;e] .lg.e[`savetable;"Failed to sort ",string[t]," due to the follwoing error: ",e]}[t]];
		.lg.o[`savetable;"attempting to save ",(string count value t)," rows of table ",(string t)," to ",string d];
		c:.[{[d;p;t] (` sv .Q.par[d;p;t],`) set .Q.en[d;.save.manipulate[t;value t]]; (1b;`)};(d;p;t);{(0b;x)}];
		/-print the result of saving the table
		$[first c;.lg.o[`savetable;"successfully saved table ",string t];
			.lg.e[`savetable;"failed to save table ",(string t),", error was: ", c 1]]];
	/-clear tables based on flags provided earlier
	$[onlyclearsaved;
		$[first c;cleartable[t];
			.lg.o[`savetable;"table "(string t)," was not saved correctly and will not be wiped"]];
		cleartable[t]];
	/-garbage collection if specified
	if[gc;.gc.run[]]
	}

/-historical write down process 
writedown:{[directory;partition] 
	/-get all tables in to namespace except the ones you want to ignore
	t:t iasc count each value each t:tables[`.] except ignorelist;
	savetable[directory;partition] each t;
	}

/-extendable function to pass to all connected hdbs at the end of day routine
hdbmessage:{[d] (`reload;d)}

/-function to reload an hdb
notifyhdb:{[h;d]
	/-if you can connect to the hdb - call the reload function 
	@[h;hdbmessage[d];{.lg.e[`notifyhdb;"failed to send reload message to hdb on handle: ",x]}];
	};

endofday:{[date]
	/-add date+1 to the rdbpartition global
	rdbpartition,:: date +1;
	.lg.o[`rdbpartition;"rdbpartition contains - ","," sv string rdbpartition];
	/-if reloadenabled is true, then set a global with the current table counts and then escape
	if[reloadenabled;
			eodtabcount:: tables[`.] ! count each value each tables[`.];
			.lg.o[`endofday;"reload is enabled - storing counts of tables at EOD : ",.Q.s1 eodtabcount];
			/-set eod attributes on gateway for rdb
			gateh:exec w from .servers.getservers[`proctype;.rdb.gatewaytypes;()!();0b;0b];
			.async.send[0b;;(`setattributes;.proc.procname;.proc.proctype;.proc.getattributes[])] each neg[gateh];
			.lg.o[`endofday;"Escaping end of day function"];:()];
	t:tables[`.] except ignorelist;
	/-get a list of pairs (tablename;columnname!attributes)
	a:{(x;raze exec {(enlist x)!enlist((#);enlist y;x)}'[c;a] from meta x where not null a)}each tables`.;
	/-save and wipe the tables
	writedown[hdbdir;date];
	/-reset timeout to original timeout
	restoretimeout[];
	/-reapply the attributes
	/-functional update is equivalent of {update col:`att#col from tab}each tables
	(![;();0b;].)each a where 0<count each a[;1];
	rmdtfromgetpar[date];
	/-invoke any user defined post replay function
	.save.postreplay[hdbdir;date];
	/-notify all hdbs
	hdbs:distinct raze {exec w from .servers.getservers[x;y;()!();1b;0b]}'[`proctype`procname;(hdbtypes;hdbnames)];
	notifyhdb[;date] each hdbs;
	};
	
reload:{[date]
	.lg.o[`reload;"reload command has been called remotely"];
	/-get all attributes from all tables before they are wiped
	/-get a list of pairs (tablename;columnname!attributes)
	a:{(x;raze exec {(enlist x)!enlist((#);enlist y;x)}'[c;a] from meta x where not null a)}each tabs:subtables except ignorelist;
	/-drop off the first eodtabcount[tab] for each of the tables
	dropfirstnrows each tabs;
	rmdtfromgetpar[date];
	/-reapply the attributes
	/-functional update is equivalent of {update col:`att#col from tab}each tables
	(![;();0b;].)each a where 0<count each a[;1];
	/-garbage collection if enabled
	if[gc;.gc.run[]];
	/-reset eodtabcount back to zero for each table (in case this is called more than once)
	eodtabcount[tabs]:0;
	/-restore original timeout back to rdb
	restoretimeout[];
	.lg.o[`reload;"Finished reloading RDB"];
	};
	
/-drop date from rdbpartition
rmdtfromgetpar:{[date] 
	rdbpartition:: rdbpartition except date;
	.lg.o[`rdbpartition;"rdbpartition contains - ","," sv string rdbpartition];
	}
	
dropfirstnrows:{[t]
	/-drop the first n rows from a table
	n: 0^ eodtabcount[t];
	.lg.o[`dropfirstnrows;"Dropping first ",(sn:string[n])," rows from ",(st:string t),". Current table count is : ", string count value t];
	.[@;(`.;t;n _);{[st;sn;e].lg.e[`dropfirstnrows;"Failed to drop first ",sn," row from ",st,". The error was : ",e]}[st;sn]];
	.lg.o[`dropfirstnrows;st," now has ",string[count value t]," rows."];
	};

subscribe:{[]
	if[count s:.sub.getsubscriptionhandles[tickerplanttypes;();()!()];;
		.lg.o[`subscribe;"found available tickerplant, attempting to subscribe"];
		/-set the date that was returned by the subscription code i.e. the date for the tickerplant log file
		/-and a list of the tables that the process is now subscribing for
		subinfo: .sub.subscribe[subscribeto;subscribesyms;schema;replaylog;first s];
		/-setting subtables and tplogdate globals
		@[`.rdb;;:;]'[key subinfo;value subinfo]]}
	
setpartition:{[]
	part: $[parvaluesrc ~ `log; /-get date from the tickerplant log file
		[.lg.o[`setpartition;"setting rdbpartition from date in tickerplant log file name :",string tplogdate];tplogdate];
	parvaluesrc ~ `tab;	  /-look at the time column in the biggest table and take the first time value and cast to date (time has be to be timestamp/datetime to get a valid date)
		[largesttab: first subtables idesc count each value each subtables;
		.lg.o[`setpartition;"setting rdbpartition from largest table (",string[largesttab],")."];.[$;(`date;first largesttab[`time]);0Nd]];
		0Nd];  /-else just return null
	rdbpartition:: enlist pardefault ^ part;	
	.lg.o[`setpartition;"rdbpartition contains - ","," sv string rdbpartition];}
	
/-api function to call to return the partitions in the rdb
getpartition:{[] rdbpartition}
	
/-function to check that the tickerplant is connected and subscription has been setup
notpconnected:{[]
	0 = count select from .sub.SUBSCRIPTIONS where proctype in .rdb.tickerplanttypes, active}

/-resets timeout to 0 before EOD writedown
timeoutreset:{.rdb.timeout:system"T";system"T 0"};
restoretimeout:{system["T ", string .rdb.timeout]};
\d .

/- make sure that the process will make a connection to each of the tickerplant and hdb types
.servers.CONNECTIONS:distinct .servers.CONNECTIONS,.rdb.hdbtypes,.rdb.tickerplanttypes,.rdb.gatewaytypes

/-set the upd function in the top level namespace
upd:.rdb.upd

/-set u.end for the tickerplant to call at end of day
.u.end:.rdb.endofday

/-set the reload the function
reload:.rdb.reload

/-load the sort csv
.sort.getsortcsv[.rdb.sortcsv]

.lg.o[`init;"searching for servers"];

//check if tickerplant is available and if not exit with error 
.servers.startupdepcycles[.rdb.tickerplanttypes;.rdb.tpconnsleepintv;.rdb.tpcheckcycles]
.rdb.subscribe[]; 

/-set the partition that is held in the rdb (for use by the gateway)
.rdb.setpartition[]

/-change timeout to zero before eod flush
.timer.repeat[.eodtime.nextroll-00:01;0W;1D;
  (`.rdb.timeoutreset;`);"Set rdb timeout to 0 for EOD writedown"];
