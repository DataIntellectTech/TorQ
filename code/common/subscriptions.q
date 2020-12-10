/-script to create subscriptions, e.g. to tickerplant

\d .sub

AUTORECONNECT:@[value;`AUTORECONNECT;1b];									//resubscribe to processes when they come back up
checksubscriptionperiod:(not @[value;`.proc.lowpowermode;0b]) * @[value;`checksubscriptionperiod;0D00:00:10]  	//how frequently you recheck connections.  0D = never

/-table of subscriptions
SUBSCRIPTIONS:([]procname:`symbol$();proctype:`symbol$();w:`int$();table:();instruments:();createdtime:`timestamp$();active:`boolean$());

getsubscriptionhandles:{[proctype;procname;attributes]
	/-grab data from .serves.SERVERS, add handling for passing in () as an argument
	data:{select procname,proctype,w from x}each .servers.getservers[;;attributes;1b;0b]'[`proctype`procname;(proctype;procname)];
	$[0h in type each (proctype;procname);distinct raze data;inter/[data]]
	}

updatesubscriptions:{[proc;tab;instrs]
	/-delete any inactive subscriptions
	delete from `.sub.SUBSCRIPTIONS where not active;
	if[instrs~`;instrs,:()];
	.sub.SUBSCRIPTIONS::0!(4!SUBSCRIPTIONS)upsert enlist proc,`table`instruments`createdtime`active!(tab;instrs;.proc.cp[];1b);
	}

reconnectinit:0b;		//has the reconnect custom function been initialised
subscribe:{[tabs;instrs;setschema;replaylog;proc]
	/-if proc dictionary is empty then exit - no connection
	if[0=count proc;.lg.o[`subscribe;"no connections made"]; :()];

	/-check required flags are set, and add a definintion to the reconnection logic
	/-when the process is notified of a new connection, it will try and resubscribe
	if[(not .sub.reconnectinit)&.sub.AUTORECONNECT;
		$[.servers.enabled;
			[.servers.connectcustom:{x@y;.sub.autoreconnect[y]}[.servers.connectcustom]; .sub.reconnectinit:1b];
			.lg.o[`subscribe;"autoreconnect was set to true but server functionality is disabled - unable to use autoreconnect"]]];
	/-check the tables which are available on the server to subscribe to
	utabs:@[proc`w;(key;`.u.w);()];
	subtabs:$[tabs~`;utabs;tabs];
	/-make tabs a list if it isn't already
	subtabs,:();
	.lg.o[`subscribe;"attempting to subscribe to ",(","sv string subtabs)," on handle ",string proc`w];
	/-if the process has already been subscribed to
	if[not instrs~`; instrs,:()];
	s:select from SUBSCRIPTIONS where ([]procname;proctype;w)~\:proc, table in subtabs,instruments~\:instrs, active;
	if[count s;
		.lg.o[`subscribe;"already subscribed to specified instruments from  ",(","sv string s`table)," on handle ",string proc`w];
		subtabs:subtabs except s`table];

	/-if all the tables have been subscribed to on specified instruments
	if[0=count subtabs; :()];
	/-if the requested tables aren't available, ignore them and log a message
	if[count e:subtabs except utabs;
		.lg.o[`subscribe;"tables ",("," sv string e)," are not available to be subscribed to, they will be ignored"];
		subtabs:subtabs inter utabs;];
	/-subscribe and get the details for the tables
	/-if replaylog is false,dont try to get the log file details - they may not exist
	/-set the function to send to the server based on this
	.lg.o[`subscribe;"getting details from the server"];
	df:{(.u.sub\:[x;y];(.u`i`L);(.u `icounts);(.u `d))};
	details:@[proc`w;(df;subtabs;instrs);{.lg.e[`subscribe;"subscribe failed : ",x];()}];
	/-to be returned at end of function (null if there is no log)
	logdate: 0Nd;
	if[count details;
		if[setschema;
			.lg.o[`subscribe;"setting the schema definition"];
			/-the first element of details is a list of pairs (tablename; schema)
			/-this is the same as (tablename set schema)each table subscribed to
			(@[`.;;:;].)each details[0] where not nulldetail:0=count each details 0;];
		if[replaylog&not null details[1;1];
			.lg.o[`subscribe;"replaying the log file"];
			/-store the orig version of upd
			origupd:@[value;`..upd;{{[x;y]}}];
			/-only use tables user has access to
			if[count where nulldetail;
				tabs:(details[0] where not nulldetail)[;0];
				subtabs:tabs inter subtabs];
			/-set the replayupd function to be upd globally
			if[not (tabs;instrs)~(`;`);
				.lg.o[`subscribe;"using the .sub.replayupd function as not replaying all tables or instruments"];
				@[`.;`upd;:;.sub.replayupd[origupd;subtabs;instrs]]];
			/-the second element of details is a pair (log count;logfile)
			@[{-11!x;};details 1;{.lg.e[`subscribe;"could not replay the log file: ", x]}];
			/-reset the upd function back to original upd
			@[`.;`upd;:;origupd]];
		if[replaylog&null details[1;1];
			.lg.e[`subscribe;"replaylog set to true but TP not using log file"]];
		/-insert the details into the SUBSCRIPTIONS table
		.lg.o[`subscribe;"subscription successful"];
		updatesubscriptions[proc;;instrs]each subtabs];
		/-return the names of the tables that have been subscribed for and
		/-the date from the name of thr tickerplant log file (assuming the tp log has a name like `: sym2014.01.01
		/-plus .u.i and .u.icounts if existing on TP - details[1;0] is .u.i, details[2] is .u.icounts (or null)
		(`subtables`tplogdate!(details[0;;0];(first "D" $ -10 sublist string last details 1)^logdate)),{(where 101 = type each x)_x}(`i`icounts`d)!(details[1;0];details[2];details[3])
	}

/-wrapper function around upd which is used to only replay syms and tables from the log file that
/-the subscriber has requested
replayupd:{[f;tabs;syms;t;x]
	/-escape if the table is not one of the subscription tables
	if[not (t in tabs) or tabs ~ `;:()];
	/-if subscribing for all syms then call upd and then escape
	if[syms ~ `; f[t;x];:()];
	/-filter down on syms
	/-assuming the the log is storing messages (x) as arrays as opposed to tables
	c:cols[`. t];
	/-convert x into a table
	x:select from $[type[x] in 98 99h; x; 0>type first x;enlist c!x;flip c!x] where sym in syms;
 	/-call upd on the data
	f[t;x]
	}

checksubscriptions:{update active:0b from `.sub.SUBSCRIPTIONS where not w in key .z.W;}

retrysubscription:{[row]
	subscribe[row`table;$[((),`) ~ insts:row`instruments;`;insts];0b;0b;3#row];
	}
//-if something becomes available again try to reconnect to any previously subscribed tables/instruments
autoreconnect:{[rows]
	s:select from SUBSCRIPTIONS where ([]procname;proctype)in (select procname, proctype from rows), not active;
	s:s lj 2!select procname,proctype,w from rows;
	if[count s;.sub.retrysubscription each s];
	}

pc:{[result;W] update active:0b from `.sub.SUBSCRIPTIONS where w=W;result}
/-set .z.pc handler to update the subscriptions table
.z.pc:{.sub.pc[x y;y]}@[value;`.z.pc;{[x]}];

/- if timer is set, trigger reconnections
$[.timer.enabled and checksubscriptionperiod > 0;
    .timer.rep[.proc.cp[];0Wp;checksubscriptionperiod;(`.sub.checksubscriptions`);0h;"check all subscriptions are still active";1b];
  checksubscriptionperiod > 0;
    .lg.e[`subscribe;"checksubscriptionperiod is set but timer is not enabled"];
  ()]
