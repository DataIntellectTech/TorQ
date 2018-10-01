// Script to replay tickerplant log files

\d .replay

// Variables
firstmessage:@[value;`firstmessage;0]			// the first message to execute
autoreplay:@[value;`autoreplay;1b]                      // replay tplogs automatically set to 1b to be backward compatible.
lastmessage:@[value;`lastmessage;0W]			// the last message to replay
messagechunks:@[value;`messagechunks;0W]		// the number of messages to replay at once
schemafile:@[value;`schemafile;`]			// the schema file to load data in to
tablelist:@[value;`tablelist;enlist `all]		// the tables to replay into (to allow subsets of tp logs to be replayed).  `all means all
hdbdir:@[value;`hdbdir;`]				// the hdb directory to write to	
tplogfile:@[value;`tplogfile;`]				// the tp log file to replay.  Only this or tplogdir should be used (not both)
tplogdir:@[value;`tplogdir;`]				// the tp log directory to read the log files from.  Only this or tplogfile should be used (not both)
partitiontype:@[value;`partitiontype;`date]		// the partitioning of the database.  Can be date, month or year (int would have to be handled bespokely)
emptytables:@[value;`emptytables;1b]			// whether to overwrite any tables at start up
sortafterreplay:@[value;`sortafterreplay;1b]		// whether to re-sort the data and apply attributes at the end of the replay.  Sort order is determined by the sortcsv (:config/sort.csv)
basicmode:@[value;`basicmode;0b]			// do a basic replay, which replays everything in, then saves it down with .Q.hdpf[`::;d;p;`sym]
exitwhencomplete:@[value;`exitwhencomplete;1b]		// exit when the replay is complete
checklogfiles:@[value;`checklogfiles;0b] 		// check if the log file is corrupt, if it is then write a new "good" file and replay it instead
gc:@[value;`gc;1b]					// garbage collect at appropriate points (after each table save and after the full log replay)
upd:@[value;`upd;{{[t;x] insert[t;x]}}]			// default upd function used for replaying data
clean:@[value;`clean;1b]                                // clean existing folders on start up. Needed if a replay     screws up and we are replaying by chunk or multiple tp logs
sortcsv:@[value;`sortcsv;`:config/sort.csv]		//location of  sort csv file

compression:@[value;`compression;()]                      	//specify the compress level, empty list if no required
partandmerge:@[value;`partandmerge;0b]				//setting to do a replay where the data is partitioned and then merged on disk
tempdir:@[value;`tempdir;`:tempmergedir]		        //location to save data for partandmerge replay
mergenumrows:@[value;`mergenumrows;10000000];                   //default number of rows for merge process
mergenumtab:@[value;`mergenumtab;`quote`trade!10000 50000];     //specify number of rows per table for merge process

/ - settings for the common save code (see code/common/save.q)
.save.savedownmanipulation:@[value;`savedownmanipulation;()!()] 	// a dict of table!function used to manipuate tables at EOD save
.save.postreplay:@[value;`postreplay;{{[d;p] }}]			// post replay function, invoked after all the tables have been written down for a given log file

// set up the usage information
.proc.extrausage:"Log Replay:\n 
 This process is used to replay tickerplant log files.
 There are multiple options which can be set either in the config files or via the standard command line switches e.g. -.replay.firstmessage 20
 \n
 It can be used to replay full files and partial files, either in chunks or all at once.  Specific tables can be selected.
 It can either overwrite existing tables, or append to them. It can create empty tables to start with. 
 Different tables can be sorted and started differently. Tables can be manipulated when saved.  
 A postreplay hook allows extra actions to be taken once the tables are saved down.
 \n 
 [-.replay.schemafile x]\t\t\tThe schema file to load.  Must not be null 
 [-.replay.hdbdir x]\t\t\t\tThe hdb directory to write data to.  Must not be null
 [-.replay.tplogfile x]\t\t\t\tThe tickerplant log file to replay. Either this or tplogdir must be set
 [-.replay.tplogdir x]\t\t\t\tA directory containing tickerplant log files to replay.  All the files in the directory will be replayed.
 [-.replay.tablelist x]\t\t\t\tThe list of tables to replay. `all for all tables
 [-.replay.firstmessage n]\t\t\tThe first message number to replay. Default is 0
 [-.replay.lastmessage n]\t\t\tThe last message number to replay. Default is 0W
 [-.replay.messagechunks n]\t\t\tThe size of message chunks to replay. If set to a negative number, the replay progress will be tracked but tables will not be saved until the end. Default is 0W
 [-.replay.partitiontype [date|month|year]] \tMethod used to partition the database - can be date, month or year. Default is date
 [-.replay.sortafterreplay [0|1]]\t\tSort the data and apply attributes on disk after the replay. Default is 1
 [-.replay.emptytables [0|1]]\t\t\tCreate empty versions of the tables in the partitions when the replay starts.  This will effectively delete any data which is already there. Default is 1
 [-.replay.basicmode [0|1]]\t\t\tDo a basic replay, which reads the table into memory then saves down with .Q.hdpf.  Is probably faster for basic replays (in-memory sort rather than on-disk). Default is 0
 [-.replay.exitwhencomplete [0|1]]\t\tProcess exits when complete. Default is 1
 [-.replay.checklogfiles [0|1]\t\t\tCheck log files for corruption, if corrupt then write a good log and replay this.  Default is 0
 [-.replay.partandmerge [0|1]\t\t\tDo a replay where the data is partitioned to a specified temp directory and then merged on disk. Default is 0
 [-.replay.compression x]\t\t\tSet the compression settings for .z.zd. Default is empty list (no compression)
 [-.replay.tempdir x]\t\t\tThe directory to save data to before moving it to the hdb. Default is the same as the hdb
 [-.replay.autoreplay [0|1]\t\tStarts replay of logs at end of script or defers start of log replay. Helpful if loading via a wrapper 
 [-.replay.clean  [0|1]\t\t Defines if the replay should zap any existing folder at the start of replay
 \n
 There are some other functions/variables which can be modified to change the behaviour of the replay, but shouldn't be done from the config file
 Instead, load the script in a wrapper script which sets up the definition
 \n
 savedownmanipulation\t\ta dictionary of tablename!function which can be used to manipulate a table before it is saved. Default is empty
 upd[tablename;data]\t\tthe function used to replay data into the tables.  Default is insert
 postreplay[d;p]\t\t\tFunction invoked when each logfile is completely replayed.  Default is set to nothing
 \n
 The behaviour upon encountering errors can be modified using the standard flags. With no flags set, the process will exit when it hits an error. 
 To trap an error and carry on, use the -trap flag
 To stop at error and not exit, use the -stop flag
 "
// check for a usage flag
if[`.replay.usage in key .proc.params; -1 .proc.getusage[]; exit 0];

// Check if some variables are null
// some must be set
.err.exitifnull each `.replay.schemafile`.replay.hdbdir, $[all null (tplogdir;tplogfile); `.replay.tplogfile; ()];

if[basicmode and (messagechunks within (0;-1 + 0W));
 .err.ex[`replayinit; "if using basic mode, messagechunks must not be used (it should be set to 0W). basicmode will use .Q.hdpf to overwrite tables at the end of the replay";1]];
if[not partitiontype in `date`month`year; .err.ex[`replayinit;"partitiontype must be one of `date`month`year";1]];

if[messagechunks=0;.err.ex[`replayinit;"messagechunks value cannot be 0";2]];

trackonly:messagechunks < 0 
if[trackonly;.lg.o[`replayinit;"messagechunks value is negative - log replay progress will be tracked"]];
messagechunks:abs messagechunks;

if[partandmerge and hdbdir = tempdir;.err.ex[`replayinit;"if using partandmerge replay, tempdir must be set to a different directory than the hdb";1]];
if[partandmerge and sortafterreplay;(sortafterreplay:0b; .lg.o[`replayinit;"Setting sortafterreplay to 0b"])];

// load the schema 
\d . 
.lg.o[`replayinit;"loading schema file ",string .replay.schemafile]
@[system;"l ",string .replay.schemafile;{.err.ex[`replayinit;"failed to load replay file ",(string x)," - ",y;2]}[.replay.schemafile]]
\d .replay

// reset the table list if we are to replay all tables
tablestoreplay:$[tablelist~enlist`all; tables[`.]; tablelist,()]
.lg.o[`replayinit;"table list is set to "," " sv string tablestoreplay];

.lg.o[`replayinit;"hdb directory is set to ",string hdbdir:hsym hdbdir];

// get the list of log files to replay
logstoreplay:$[not null tplogfile; 
		[if[()~key hsym tplogfile; .err.ex[`replayinit;"specified tplogfile ",(string tplogfile)," does not exist";3]];
		 enlist hsym tplogfile]; 
		[.lg.o[`replayinit;"reading log files from directory ",string tplogdir];
		 if[()~key hsym tplogdir; .err.ex[`replayinit;"specified tplogdir ",(string tplogdir)," does not exist";4]];
		 raze ` sv' tplogdir,/:key tplogdir:hsym tplogdir]];

if[0=count logstoreplay;.err.ex[`replayinit;"failed to find any tickerplant logs to replay";5]]
.lg.o[`replayinit;"tp logs to replay are "," " sv string logstoreplay]

// the path to the table to save
pathtotable:{[h;p;t] `$(string .Q.par[h;partitiontype$p;t]),"/"}

// create empty tables - we need to make sure we only create them once
emptytabs:`symbol$()
createemptytable:{[h;p;t;td]
 $[partandmerge;dest:td;dest:h];
 if[(not (path:pathtotable[dest;p;t]) in .replay.emptytabs) and .replay.emptytables;
  .lg.o[`replay;"creating empty table ",(string t)," at ",string path];
  .replay.emptytabs,:path;
  savetabdatatrapped[h;p;t;0#value t;0b]]}

savetabdata:{[h;p;t;data;UPSERT;td]
 $[partandmerge;path:pathtotable[td;p;t];path:pathtotable[h;p;t]];
 if[not partandmerge;.lg.o[`replay;"saving table ",(string t)," to ",string path]];
 .replay.pathlist[t],:path;
 $[partandmerge;savetablesbypart[td;p;t;h];$[UPSERT;upsert;set] . (path;.Q.en[h;0!.save.manipulate[t;data]])]
  }

savetabdatatrapped:{[h;p;t;data;UPSERT;td] .[savetabdata;(h;p;t;data;UPSERT;td);{.lg.e[`replay;"failed to save table : ",x]}]}

// this function should be invoked for saving tables
savetab:{[td;h;p;t]
 if[not partandmerge;createemptytable[h;p;t;td]];
 if[count value t;
  .lg.o[`replay;"saving ",(string t)," which has row count ",string count value t];
  savetabdatatrapped[h;p;t;value t;1b;td];
  delete from t;
  if[gc;.gc.run[]]]}

// function to apply the sorting and attributes at the end of the replay
// input is a dictionary of tablename!(list of paths)
// should be the same as .replay.pathlist
applysortandattr:{[pathlist]
	// convert pathlist dictionary into a keys and values then transpose before passing into .sort.sorttab
	.sort.sorttab each flip (key;value) @\: distinct each pathlist
	};
 
// Given a list of table names, return the list in order according to the table counts
// this is used at save down time as it should minimise memory usage to save the smaller tables first, and then garbage collect
tabsincountorder:{x iasc count each value each x}

// check if the count has been exceeded, and save down if it has
currentcount:0
totalcount:0
checkcount:{[h;p;counter;td]
 currentcount+::counter;
 if[.replay.currentcount >= .replay.messagechunks;
  $[.replay.trackonly;
    [.replay.totalcount +: .replay.currentcount;
     .lg.o[`replay;"replayed a chunk of ",(string .replay.messagechunks)," messages.  Total message count so far is ",string .replay.totalcount]];
    [.lg.o[`replay;"number of messages to replay at once (",(string .replay.messagechunks),") has been exceeded.  Saving down"]; 
     savetab[td;h;p] each tabsincountorder[.replay.tablestoreplay]; 
     .lg.o[`replay;"save complete- replaying next chunk of data"]]];
  .replay.currentcount:0]}

// function used to finish off the replay
// generally this will be to re-sort the table, and set an attribute
finishreplay:{[h;p;td]
 // save down any tables which haven't been saved
 savetab[td;h;p] each tabsincountorder[.replay.tablestoreplay];
 // sort data and apply the attributes
 if[sortafterreplay;applysortandattr[.replay.pathlist]];

 if[partandmerge;postreplaymerge[td;p;h]];

 // invoke any user defined post replay function
 .save.postreplay[h;p];
 }

replaylog:{[logfile]
 // set the upd function to be the initialupd function
 .replay.msgcount:.replay.currentcount:.replay.totalcount:0;
 // check if logfile is corrupt
 if[checklogfiles; logfile: .tplog.check[logfile;lastmessage]];
 $[firstmessage>0;
	[.lg.o[`replay;"skipping first ",(string firstmessage)," messages"];
         @[`.;`upd;:;.replay.initialupd]];
	@[`.;`upd;:;.replay.realupd]];
 .replay.tablecounts:.replay.errorcounts:.replay.pathlist:()!();
 .replay.replaydate:"D"$-10#string logfile;
 if[ .replay.clean and (`$st:string .replay.replaydate) in key hdbdir;
    .lg.o[`replay;"HDB directory already contains ",st," partition. Deleting from the HDB directory"];
    .os.deldir .os.pth[.Q.par[hdbdir;.replay.replaydate;`]]; // delete the current dates HDB directory before performing replay
  ];
 if[lastmessage<firstmessage; .lg.o[`replay;"lastmessage (",(string lastmessage),") is less than firstmessage (",(string firstmessage),"). Not replaying log file"]; :()];
 .lg.o[`replay;"replaying data from logfile ",(string logfile)," from message ",(string firstmessage)," to ",(string lastmessage),". Message indices are from 0 and inclusive - so both the first and last message will be replayed"];
 // when we do the replay, need to move the indexing, otherwise we wont replay the last message correctly
 -11!($[lastmessage<0W; lastmessage+1;lastmessage];logfile);
 .lg.o[`replay;"replayed data into tables with the following counts: ","; " sv {" = " sv string x}@'flip(key .replay.tablecounts;value .replay.tablecounts)];
 if[count .replay.errorcounts;
  .lg.e[`replay;"errors were hit when replaying the following tables: ","; " sv {" = " sv string x}@'flip(key .replay.errorcounts;value .replay.errorcounts)]];
 // set compression level
 if[ 3= count compression;
   .lg.o[`compression;"setting compression level to (",(";" sv string compression),")"];
   .z.zd:compression;
   .lg.o[`compression;".z.zd has been set to (",(";" sv string .z.zd),")"]];

 $[basicmode; 
  [.lg.o[`replay;"basicmode set to true, saving down tables with .Q.hdpf"];
   .Q.hdpf[`::;hdbdir;partitiontype$.replay.replaydate;`sym]];
  // if not in basic mode, then we need to finish off the replay  
  finishreplay[hdbdir;.replay.replaydate;tempdir]];
  if[gc;.gc.run[]];}

// upd functions down here
realupd:{[f;t;x] 
	// increment the tablecounts
        tablecounts[t]+::count first x;
	// run the supplied function in the error trap
	.[f;(t;x);{[t;x;e] errorcounts[t]+::count first x}[t;x]];
	}[.replay.upd]

// amend the upd function to filter based on the table list
if[not tablelist~enlist `all; realupd:{[f;t;x] if[t in .replay.tablestoreplay; f[t;x]]}[realupd]]

// amend to do chunked saves
if[messagechunks < 0W; realupd:{[f;t;x] f[t;x]; checkcount[hdbdir;replaydate;1;tempdir]}[realupd]]

initialupd:{[t;x] 
	 // spin through the first X messages
	 $[msgcount < (firstmessage - 1);
	msgcount+::1;
	// Once we reach the correct message, reset the upd function
	@[`.;`upd;:;.replay.realupd]]
	}

// extract user defined row counts
mergemaxrows:{[tabname] mergenumrows^mergenumtab[tabname]};

// post replay function for merge replay, invoked after all the tables have been written down for a given log file
postreplaymerge:{[td;p;h] 

 mergelimits:(tabsincountorder[.replay.tablestoreplay],())!({[x] mergenumrows^mergemaxrows[x]}tabsincountorder[.replay.tablestoreplay]),();	
 // merge the tables from each partition in the tempdir together
 merge[td;p;;mergelimits;h] each tabsincountorder[.replay.tablestoreplay];
 .os.deldir .os.pth[string .Q.par[td;p;`]]; // delete the contents of tempdir after merge completion
 }

// function to upsert to specified directory
upserttopartition:{[h;dir;tablename;tabdata;pt;expttype;expt]
 dirpar:.Q.par[dir;pt;`$string first expt];
 directory:` sv dirpar,tablename,`;
 // make directories for tables if they don't exist
 if[count tabpar:tabsincountorder[.replay.tablestoreplay] except key dirpar;
  .lg.o[`dir;"creating directories under ",1_string dirpar];
  tabpar:tabpar except `heartbeat`logmsg;
  .[{[d;h;t](` sv d,t,`) set .Q.en[h;0#value t]};] each dirpar,'h,'tabpar];
  .lg.o[`save;"saving ",(string tablename)," data to partition ",string directory];
  .[
  upsert;
  (directory;r:update `sym!sym from ?[tabdata;{(x;y;(),z)}[in;;]'[expttype;expt];0b;()]);
  {[e] .lg.e[`savetablesbypart;"Failed to save table to disk : ",e];'e}];
  };

savetablesbypart:{[dir;pt;tablename;h]
 arows: count value tablename;	
 .lg.o[`rowcheck;"the ",(string tablename)," table consists of ", (string arows), " rows"];		
 // get additional partition(s) defined by parted attribute in sort.csv		
 extrapartitiontype:.merge.getextrapartitiontype[tablename];
	
 // check each partition type actually is a column in the selected table
 .merge.checkpartitiontype[tablename;extrapartitiontype];		
 // enumerate data to be upserted
 enumdata:update (`. `sym)?sym from .Q.en[h;value tablename];
 // get list of distinct combiniations for partition directories
 extrapartitions:(`. `sym)?.merge.getextrapartitions[tablename;extrapartitiontype];

 .lg.o[`save;"enumerated ",(string tablename)," table"];		
 // upsert data to specific partition directory 
 upserttopartition[h;dir;tablename;enumdata;pt;extrapartitiontype] each extrapartitions;				
 // empty the table
 .lg.o[`delete;"deleting ",(string tablename)," data from in-memory table"];
 @[`.;tablename;0#];
 // run a garbage collection (if enabled)
 if[gc;.gc.run[]];
 };


merge:{[dir;pt;tablename;mergelimits;h]
 // get int partitions
 intpars:asc key ` sv dir,`$string pt; // list of enumerated partitions 0 1 2 3...
 k:key each intdir:.Q.par[hsym dir;pt] each intpars; // list of table names
 if[0=count raze k inter\: tablename; :()]; 
 // get list of partition directories containing specified table
 partdirs:` sv' (intdir,'parts) where not ()~/:parts:k inter\: tablename; // get each of the directories that hold the table
 
 // exit function if no subdirectories are found
 if[0=count partdirs; :()];
 // merge the data in chunks depending on max rows for table
 // destination for data to be userted to [backslashes corrected for windows]
        
 dest:` sv .Q.par[h;pt;tablename],`; // provides path to where to move data to	
 {[tablename;dest;mergemaxrows;curr;segment;islast]
 .lg.o[`merge;"reading partition ", string segment];
 curr[0]:curr[0],select from get segment;
 curr[1]:curr[1],segment;
 $[islast or mergemaxrows < count curr[0];
  [.lg.o[`merge;"upserting ",(string count curr[0])," rows to ",string dest];
  dest upsert curr[0];
  .lg.o[`merge;"removing segments", (", " sv string curr[1])];
  .os.deldir each string curr[1];
  (();())];
  curr]
 }[tablename;dest;(mergelimits[tablename])]/[(();());partdirs; 1 _ ((count partdirs)#0b),1b];   
 // set the attributes
 .lg.o[`merge;"setting attributes"];
  
 @[dest;;`p#] each .merge.getextrapartitiontype[tablename]; 
 .lg.o[`merge;"merge complete"];
 // run a garbage collection (if enabled)
 if[gc;.gc.run[]];
 };


\d .
//load the sort csv
.sort.getsortcsv[.replay.sortcsv]



if[.replay.autoreplay;
  .lg.o[`replay;"replay starting from script by default"];
  .replay.replaylog each .replay.logstoreplay;
  .lg.o[`replay;"replay complete"];
  if[.replay.exitwhencomplete; exit 0];
  ];

