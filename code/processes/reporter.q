/- Reporter Process for TorQ
/- Glen Smith. glen.smith@aquaq.co.uk

/ - defining default process parameters
inputcsv:@[value;`.rp.inputcsv;.proc.getconfigfile["reporter.csv"]];		/ - location of the reporter process configuration file
writetostdout:@[value;`.rp.writetostdout;0b];							/ - determine if the process should write to stdout
flushqueryloginterval:@[value;`.rp.flushqueryloginterval;0D00:02:00]	/ - how often the query logs are flushed
queryid:`long$0;														/ - initial query id value

inputcsv:string inputcsv

/- stores report information
reports:([] name:`$(); query:(); resulthandler:(); gateway:(); joinfunction:(); proctype:(); procname:(); start:`minute$(); end:`minute$(); period:`minute$(); timeoutinterval:`timespan$(); daysofweek:());

/- status of current queries
querystatus:([queryid:`u#`long$()] name:`symbol$(); time:`timestamp$(); servertype:(); timeout:`timespan$(); submittime:`timestamp$(); returntime:`timestamp$(); status:`boolean$(); stage:`$());

/- table storing log messages for each step of report
querylogs:([] time:`timestamp$(); queryid:`g#`long$(); stage:`$(); message:());

/- used for publishing results
reporterprocessresults:([] queryid:();time:`timestamp$();sym:`$();result:());

/- used for purging .timer.timer of old timers
timerids:([id:()] periodend:())

/- returns a table of reports currently active
activereports:{select from reports where (.proc.cd[] mod 7) in/: daysofweek, end>.proc.ct[]};

/- queryid used as an unique identifier
nextqueryid:{queryid+:1;queryid};

/- puts process information into a dictionary [nm: name of report;qu: function to be evaluated;qid: query id]
wrappercols: `queryid`time`name`procname`proctype`result;
wrapper:{[name;query;qid] 
	`queryid`time`name`procname`proctype`result!(qid;.proc.cp[];name;@[value;".proc.procname";`nontorq];@[value;".proc.proctype";`nontorq];@[value;query;{"error: ",x}])};

csvloader:{[CSV]

	/- rethrows error if file doesn't exist, checks to see if correct columns exist in file
	t:@[{write[`long$0;"Opening ",x;0b];("s**s*Ssuuun*";enlist "|") 0: hsym `$x};CSV;{.lg.e[`csvloader;e:"failed to open ",x," : ",y];'e}[CSV]];
	
 	/- Replace Nested list string with actual nested list
	t:update daysofweek:value each daysofweek, query:raze each query, proctype:raze each `$" " vs' string proctype from t;
	/ check if the reporter.csv file matches the global table reports
  	$[not all (cols reports) in cols t;
		'"The file (",CSV,") has incorrect layout";
	  / - check if there are any null values or empty strings in required columns
	  any (not count each raze value exec query,resulthandler from t),null raze/[value flip delete query,resulthandler,joinfunction,gateway,procname from t];
		'"File not loaded, null values were found in the csv file";
	  / - cannot query against more than one processes when server is not a gateway process
	  any 1<count each exec proctype from t where null gateway;
		'"There cannot be more than 1 process types defined when gateway is null";
	  / check to ensure that a join function has been specified where a gateway is the server
	  any not count each exec joinfunction from t where not null gateway;
		'"joinfunction cannot be null if gateway is not null";
	/ - else all validation checks pass and upsert CSV data into the reports table
	[`..reports upsert t;write[`long$0;"Loaded  ",CSV;0b]]];
	};	
	
/- checks if current day has any reports to be scheduled
datecheck:{
  flushtimer[];
  @[runreport';activereports[];{write[`long$0;x;1b]}];};

/- returns next nearest period timestamp, if period is 00:00:00 it will return start time and only runs once.
nextperiod:{[start;end;period;curr] 
	`timestamp$ .proc.cd[] + $[0i=`int$period;
				start;
				first d where (d:s + sums 0,(`int$((`time$end)-s:`time$start)%p)#p:`time$period) >= `time$curr]}

/- checks if any queries have timed out
checktimeout:{
	/- select back any queries that have not completed and have ran past their timeout period
	timedout:select queryid,timeout from querystatus where not timeout=0Wn,.proc.cp[]>time+timeout,null returntime,status=0b;
	/- if nothing returned, then escape
	if[not count timedout;:()];
	/ - end each query and that has exceeded their time out value and write a log value
	qid:timedout`queryid;
	finishquery[0b;qid];
	updatestage[qid;`T;.proc.cp[]];
	{[qid] write[qid`queryid;"Exceeded specified timeout value: ",string[`time$qid`timeout];0b]} each timedout};

/- updates status of query in querystatus [st:boolean status of query; qids:int query id]
/- update status of both cases, but not returntime
finishquery:{[st;qids]
  $[st;
    update time:.proc.cp[],returntime:.proc.cp[],status:st from `..querystatus where queryid in qids;
    update time:.proc.cp[],status:1b from `..querystatus where queryid in qids]};

/- updates stage column of query in the querystatus file [qid: long;stage:symbol `R`C`E`T;timestamp: .proc.cp[]]
/- `R - Running, `C - complete, `E - Error, `T - Timed out
updatestage:{[qid;Stage;timestamp]
  $[Stage ~ `R;
    update time:timestamp,submittime:timestamp,stage:Stage from `..querystatus where queryid in qid;
  not `E ~ first exec stage from querystatus where queryid in qid;
      update time:timestamp,stage:Stage from `..querystatus where queryid in qid;
  ()]}

/- establish connection with processes on schedule and send query [tab(dictionary): single row of reports]
/- returns successful result to postback function 
runreport:{[tab]
	if[not count tab;:()];
	/ - run some validation on the input and signal an error if it doesn't passed
	if[ @[{not (all (cols value `reports) in cols x) and 99h=type x};tab;1b];
		.lg.e[`runreport;e:"Parameter must be a table and have the correct column layout"];'e];
	/- define list of function and paramters for the timer to call
	fp:(`send;tab`name;tab`query;tab`proctype;tab`procname;tab`timeoutinterval;tab`gateway);
	/ - cast the start and end times as timestamps
	endts: `timestamp $ .proc.cd[]+tab[`end]; 
	startts: `timestamp $ .proc.cd[]+tab[`start];
	/ - if the end time stamp is less than the current time, then the report cannot be scheduled for today
	if[endts < .proc.cp[]; write[`long$0;"Cannot schedule report.  Report end time (",string[endts],") has already passed";0b]; :()];
	/- return if start=end (one time query, onetime queries don't have periodend) and the report hasn't already been set on the timer
	if[(startts = endts) and not count select from .timer.timer where fp~/:funcparam,nextrun=startts;
		.timer.once[startts;fp;"Reporter - ",string tab`name];
		`..timerids upsert 1!select id,periodend:nextrun from .timer.timer where fp~/:funcparam;
	:()];
	/ - if the current time is within the start and end timestamps, use current time as start time, else use the startts
	/ - work out the start time for the timer. For example a report could run every day from 10am to 6pm every 5 mins, if the reporter
	/ - is started at 1:11pm, we need to know that the report should start 1:15pm and then run every 5 mins there after
	startts: nextperiod[tab`start;tab`end;tab`period;] $[.proc.cp[] within startts,endts;.proc.cp[];startts];
	/ - escape if the report havs already been registered on the timer
	if[count select from .timer.timer where fp~/:funcparam;:()];
	/ - register the report on the timer
	.timer.rep[startts - p;endts;p:`timespan$tab`period;fp;2h;"Reporter - ",string tab`name;0b];
	`..timerids upsert 1!select id,periodend from .timer.timer where fp~/:funcparam;
    };

/- sends async postback query to a process 
send:{[Name;query;proct;procn;timeout;gateway] 
	/ - increment the query id
	qid:nextqueryid[];
	.[sendinner;(Name;query;proct;procn;timeout;qid;gateway);{[qid;err] write[qid;"Error calling the sendinner function : ",err;1b]}[qid]]
	};
sendinner:{[Name;query;proct;procn;timeout;qid;gateway]
  	/- if gateway is not null, then gateway is the gateway type, and procn is the gateway name. proct is the list of process types to query on the gateway
	/- if gateway is null, proct is the type of the process to query, procn is the name of the process (optional)
	
	typetoquery:(first proct)^gateway;
	
	/ - set the query status as running (R)
        `..querystatus upsert (qid;Name;.proc.cp[];typetoquery;timeout;0Np;0Np;0b;`R);	

 	/ - the process does not have a registered server connection, then signal an error
	if[not count select from .servers.SERVERS where proctype in typetoquery,{$[null x;(count y)#1b;x=y]}[procn;procname];
		finishquery[0b;qid];
		.lg.e[`sendinner;e:"process with proctype=",(string typetoquery)," and procname=",(string procn)," does not exist and is not in .servers.SERVERS"];'e];
   	
	/- get the handle to run against, depending on whether a name is specified
 	hd:first $[not null procn;
			.servers.getservers[`procname;procn;()!();1b;1b]`w;
			.servers.gethandlebytype[typetoquery;`any]];	

	/ - check if server is available
	/ if[ not count select from .servers.SERVERS where w in hd,(proctype in (proct;`gateway)[gw]) or procname in procn;
	if[null hd; .lg.e[`sendinner;e:"Attempted to run report ",string[Name]," but process not available: ",string typetoquery^procn];'e];
	
	/ - submit the query to the server  
	$[not null gateway;
		[joinfunction:value first exec joinfunction from `..reports where name=Name;
		 write[qid;"Running report: ",string[Name]," against proctypes: ",(" " sv string[proct])," on a gateway: ",string[typetoquery^procn]," on handle: ",string hd;0b];
		 @[neg[hd];(gwwrapper;Name;query;qid;proct;joinfunction; `gwpostback);{.lg.e[`sendinner;e:"Asynchronous query to gateway failed: ,"x];'e}]];
		[write[qid;"Running report: ",string[Name]," against ",$[null procn;"proctype : ",string typetoquery;"procname : ",string procn]," on handle: ",.Q.s hd;0b];
		 wrappedquery:(wrapper;Name;query;qid);
		 .[.async.postback;(hd;wrappedquery;`postback);{'x}]]
	];
	/ - update the query submittime for the query id
	update submittime:.proc.cp[] from `..querystatus where queryid in qid; 
	};
	
/- postback used for async queries [result: dictionary result of query on process]
postback:{[result]  @[postbackinner;result;{[qid;err] write[qid;err;1b]}[result`queryid]]};
postbackinner:{[result]
  / - pull the query id from the data returned from the server
  queryid:result`queryid;
  res:result`result;
  write[queryid;"Received result";0b];

  /- error handling
  if[10h = type res;
    if["error:" ~ 6#res;
      finishquery[1b;queryid];
      .lg.e[`postbackinner;e:"Query execution failed on remote process ",string[result`proctype],": ",7_result`result];'e]];
  dictkeys:@[cols;result;{.lg.e[`postbackinner;e:"Result is not a dictionary"];'e}];
  columns:value `wrappercols;
  / - signal an error if the columns are not in the expected format
  if[all not dictkeys in columns;
	.lg.e[`postbackinner;e:"Incorrect column format, must be: ","; " sv string columns];'e];
  / - log that the query has completed
  finishquery[1b;queryid];
  / - find any result handlers and apply them to the rseult
  if[count resulthandler: first exec resulthandler from reports where name in result`name;
		write[queryid;"Running resulthandler";0b];
		.[{[x;y] (value x) @ y;};(resulthandler;result);{.lg.e[`postbackinner;e:"Resulthandler failed: ",x];'e}]];
  / - set the report status as complete (C)
  updatestage[queryid;`C;.proc.cp[]];
  write[queryid;"Finished report";0b];
  };

/- GATEWAY FUNCTIONALITY
/- wrapper function used for sending asynchronous queries to the gateway
gwwrapper:{[name;query;qid;procs;join;postback] 
  .gw.asyncexecjpt[query; procs; join; (postback;`queryid`time`name`procname`proctype!(qid;.proc.cp[];name;.proc.procname;.proc.proctype)); 0Wn]}

/- when the result from the gateway is recieved it is formatted before being 
/- passed onto the postback function as is normal with the non gateway queries
gwpostback:{[queryinfo; query; result] postback queryinfo,(enlist `result)!enlist result}

/- LOGGING
/- write a querylog message
write:{[qid;msg;err]

  /- special case for queries which have timedout, queries timedout even if they failed to run
  if[err~1b;updatestage[qid;`E;.proc.cp[]];.lg.e[`reporter;msg]];
  stage:$[qid=0;`S;first exec stage from querystatus where queryid in qid];
  if[writetostdout;.lg.o[`reporter;format[qid;string[stage],"|",msg]]];
  `..querylogs upsert ([] time:.proc.cp[];queryid:qid;stage:stage;message:enlist raze msg);

  /- custom handler
  writecustom[qid;msg;err]}

/- add additional functionality to the write function
writecustom:@[value;`writecustom;{{[qid;msg;err]}}]

/- flushing function to clear querylogs, only allow 1 day of logs
flushquerylogs:{[flushtime] 
  cutofftime:.proc.cp[]-flushtime;
  flushing: string fcnt:count select from `..querylogs where time <= cutofftime;
  remaining: string count[value `..querylogs] - fcnt;
  write[`long$0;"Flushing ",flushing," records. ",remaining," remaining.";0b];
  delete from `..querylogs where time <= cutofftime;}

/- flushing any stale timers from the .timer.timer table 
flushtimer:{
  currenttime:.proc.cp[];
  flushing:exec id from `..timerids where periodend<currenttime;
  remaining: string count select from `..timerids where periodend>=currenttime;
  if[count flushing; write[`long$0;"Flushing ",string[count flushing]," timers. ",remaining," still active.";0b]];
  .timer.remove each flushing;
  delete from `..timerids where id in flushing;}

/- format log message
format:{[qid;msg] raze string[.proc.cp[]],"|",string[qid],"|",msg}

/- RESULT HANDLERS
/- returns string current date time YYYY_MM_DD_HH_MM_SS_mmm
dtsuffix:{enlist ssr[;;"_"]/["_" sv string .proc.cd[],.proc.ct[];".:"]};

emailstats:([procname:(); alertname:()] lastsent:`timestamp$());

emailalert:{[period; recipients; data]
    lasttime:0p^exec first lastsent from emailstats where procname=(data`procname),alertname=(data`name);
    result:data`result;
    if[not count result; write[data`queryid;"emailalert: nothing to email";0b]; :()];
    if[period > .proc.cp[] - lasttime; write[data`queryid;"emailalert: data available to email but previous email was too soon";0b]; :()];
    
    upsert[`emailstats](data`procname; data`name; .proc.cp[]);
    subject:"Process [",(string data`procname),"] has triggered an alert [",(string data`name),"]";
    write[data`queryid;"emailalert: sending warning email";0b];
    res:.email.senddefault[`to`subject`body!(`$recipients;subject;enlist result`messages)];
    $[0<res;
	write[data`queryid; "emailalert: sent email alert for alert: ",string data`name;0b];
	write[data`queryid; "emailalert: failed to send email alert: ",string data`name;1b]]; 
   }

emailreport:{[temppath;recipients;filename;filetype;data]
    filepath:writetofile[temppath;filename;filetype;data;""];

    subject:"Report '",(string data`name),"' has been generated by TorQ [",(string .proc.cd[]),"]";
    body:"A report has been generated by TorQ. Please see the attached file for the results.";
 
    write[data`queryid;"emailreport: sending email with attached report";0b];	
    if[1>res:.email.senddefault[`to`subject`body`attachment!(`$recipients;subject;enlist body;filepath)];
	write[data`queryid;"emailreport: failed to send email";1b]];
    write[data`queryid;"emailreport: cleaning up temporary report file: ",string filepath;0b];
    .os.del[string filepath];}

/- formats table with a nested int list column into string
stringnestedlists:{[res]
  /- remove character type and empty spaces
  nestedtypes:upper .Q.t except " c";
  /- if there are any nested lists, otherwise returns original res
  $[count select from meta[res] where t in nestedtypes;
    {[t;c] ![t;();0b;(enlist c)!enlist ((';{" " sv string x});c)]}/[res;exec c from meta[res] where t in nestedtypes];
    res]};

/- writetofiletype: write to disk as specified file type [path: string;filename: string;filetype: string e.g. txt,csv;data: dictionary]
writetofile:{[path;filename;filetype;data;suffix]
  if[not (ty:`$filetype) in key .h.tx;write[data`queryid; "writetofile: filetype parameter not found in .h.tx";1b]];
  res:stringnestedlists[data`result];
  filepath:`$path,("_" sv (filename;string[data`procname]),$[count suffix;suffix;()]),".",filetype;
  .[{hsym[x] 0:.h.tx[y;z]};(filepath;ty;res);{[data;e] write[data`queryid;"writetofile: ",e;1b]}[data]]; filepath};

writetofiletype:{[path;filename;filetype;data] writetofile[path;filename;filetype;data;dtsuffix[]]}

/- save as splayed table [path: string;file: string;data: dictionary]
writetosplayed:{[path;file;data] 
	tab:stringnestedlists[data`result];
	.[{[h;t;d] h:hsym `$h; (` sv .Q.par[h;`;`$t],`) upsert .Q.en[h;0!d]};
		(path;file;tab);
		{[data;e] write[data`queryid;"writetosplayed: ",e;1b]}[data]]
	};

/- publishes results data using the reporterprocessresults table schema
publishresult:{[result]
  tablename:`reporterprocessresults;
  data:([] queryid:enlist result`queryid;time:.proc.cp[];sym:result`name;result:enlist result);
  .[.ps.publish;(tablename;data);{'"Failed to publish: ", x}]}
  
/- INITIALISE REPORTER
/- run csvloader using filepath inputcsv
@[csvloader;inputcsv;{write[`long$0;x;1b];exit 0}];

/- Add to timer and run datecheck
.timer.repeat[.proc.cp[];0Wp;0D00:00:20;(`datecheck;`);"Reporter - datecheck runs each day at midnight and schedules timers if they are needed on the current day"];
.timer.repeat[.proc.cp[];0Wp;0D00:00:05;(`checktimeout;`);"Reporter - cancel queries which have timed out"];
.timer.repeat[.proc.cp[];0Wp;0D00:02:00;(`flushquerylogs;flushqueryloginterval);"Reporter - flush querylogs table of data that is older than the parameter"];

write[`long$0;"Reporter Process Initialised";0b];
datecheck[];
/- Initialise server connections 
.servers.startup[];


