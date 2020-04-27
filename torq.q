// use -usage flag to print usage info
\d .proc

// variable to check to ensure this file is loaded - used in other files
loaded:1b
// Initialised flag - used to check if the process is still initialisation
initialised:0b

// function to add functions to initialisation list
initlist:()
initexecuted:()
addinitlist:{[x].proc.initlist,:enlist x};
  
generalusage:@[value;`generalusage;"General:
 This script should form the basis of a production kdb+ environment. 
 It can be sourced from other files if required, or used as a launch script before loading other files/directories 
 using either -load or -loaddir flags
 Currently each process has to know two things about itself - it's name and type.  These can be 
  - read from a file (the default behaviour)
  - supplied on the command line
  - set previously if sourced from other files (set .proc.proctype and .proc.procname)
 By default these are read from $KDBCONFIG/process.csv with schema 
 host,port,proctype,procname
 The process uses it's own host (either hostname or ip address) as a lookup to work out it's type and name.
 It will also check for hosts of 'localhost' if it can't find anything else, but this is a convenience and not for
 production environments.
 The name and type of the process are used to determine various things : 
  - the name of the log files to write to
  - which config to load
  - which code to load
 It will also be useful for service discovery"]

// Usage errors
// The environment usage info
envusage:@[value;`envusage;"Required environment variables:
 KDBCODE:\t\t\tthe base code directory.  This will be checked for certain folders e.g. $KDBCODE/common;$KDBCODE/handlers
 KDBCONFIG:\t\t\twhere the process configuration lives
 KDBLOG:\t\t\twhere log files are written to
 KDBHTML:\t\t\tcontains html files
 KDBLIB:\t\t\tcontains supporting library files"]
 
envoptusage:@[value;`envoptusage;"Optional environment variables:
 KDBAPPCONFIG:\t\t\twhere the app specific configuation can be found"]

// the standard options
stdoptionusage:@[value;`stdoptionusage;"Standard options:
 [-procname x -proctype y]:\tthe process name and process type.  Read from $KDBCONFIG/process.csv if not defined
 [-procfile x]:\t\t\tthe full path of the process.csv file to use to getthe details on the current process
 [-load x [y..z]]:\t\t\tthe file or database directory to load
 [-loaddir x [y..z]]:\t\t\tload all .q,.k files in specified directory
 [-trap]:\t\t\tany errors encountered during initialisation when loading external files will be caught and logged, processing will continue
 [-stop]:\t\t\tstop loading the file if an error is encountered
 [-noredirect]:\t\t\tdo not redirect std out/std err to a file (useful for debugging)
 [-noredirectalias]:\t\tdo not create an alias for the log files (aliases drop the timestamp suffix)
 [-noconfig]:\t\t\tdo not load configuration
 [-nopi]:\t\t\treset the definition of .z.pi to the initial value (useful for debugging)
 [-debug]:\t\t\tequivalent to [-nopi -noredirect]
 [-localtime]:\t\t\tuse local time instead of GMT
 [-usage]:\t\t\tprint usage info
 [-test]:\t\t\tset to run unit tests"]
 
// extra info - used to extend the usage info 
extrausage:@[value;`extrausage;""]

configusage:@[value;`configusage;"Config management: 
 More options are available in the configuration scripts.  
 All default TorQ configuration is stored in $KDBCONFIG (in the settings directory). The config is stored in q scripts.
 Unless the -noconfig flag is set, the process will attempt to read the default config module from this directory.
 Within the module, default.q will be read, followed by {proctype}.q, then {procname}.q.
 Neither {proctype}.q nor {procname}.q have to be present or fully populated.
 Values in {procname}.q will override those in {proctype}.q which will override default.q.
 The idea is to allow processes to live in different process groups, and have the configuration shared between them.
 So for example by default all processes log all messages to disk.  You can create a process type called \"tickerplant\"
 and switch off logging for all tickerplants by setting .usage.logtodisk:0b in $KDBCONFIG/tickerplant.q.  
 However, perhaps for one specific tickerplant in the group you want to switch logging on either temporarily or permanently.  
 You can do this in $KDBCONFIG/tickerplantname.q 
 Application specific configuration may be stored in a user defined directory and read after the TorQ default module.
 If the environment variable $KDBAPPCONFIG is set, then TorQ will attempt to load app specific config from $KDBAPPCONFIG (in the settings subdirectory).
 Within the app specific module, config is read in the same order as the default module (default.q, then {proctype}.q, then {procname}.q).
 The app specific config will not be read if the $KDBAPPCONFIG is not set or does not match the user defined directory. No app specific config will be read if the -noconfig flag is set.
 default.q, {proctype}.q and {procname}.q do not have to be present or fully populated."]

helpusage:@[value;`helpusage;"Help: 
 if help.q from code.kx is loaded, use help` for more information.
 if api.q is loaded, you should be able to access api information from the commandline.  Use 
	.api.f[symbol or string pattern] e.g. .api.f[`proc] to find a function/variable
	.api.p[symbol or string pattern] e.g. .api.p[`timer] to find a publically marked function/variable
	.api.u[symbol or string pattern] e.g. .api.u[`] to find a publically marked, user defined function (i.e. don't show .q functions)"] 

// If the usage value has been overridden, use that.  Else concat the req environment, with the stdoptions, with the extra usage info
getusage:{@[value;`.proc.usage;generalusage,"\n\n",envusage,"\n\n",envoptusage,"\n\n",stdoptionusage,"\n\n",extrausage,"\n\n",configusage,"\n\n",helpusage,"\n\n"]}

// The required environment variables
// The base script must have KDBCODE, KDBCONFIG, KDBLOG, KDBHTML and KDBLIB set
envvars:@[value;`envvars;`symbol$()]
envvars:distinct `KDBCODE`KDBCONFIG`KDBLOG`KDBHTML`KDBLIB,envvars
// The script may have optional environment variables
// KDBAPPCONFIG may be defined for loading app specific config
{if[not ""~getenv x; envvars::distinct x,envvars]}each `KDBAPPCONFIG`KDBSERVCONFIG

// set the torq environment variables if not already set
qhome:{q:getenv[`QHOME]; if[q~""; q:$[.z.o like "w*"; "c:/q"; getenv[`HOME],"/q"]]; q}
settorqenv:{[envvar; default] 
 if[""~getenv[envvar]; 
  .lg.o[`init;(string envvar)," is not defined. Defining it to ",val:qhome[],"/",default];	
  setenv[envvar; val]];}

// make sure the path separators are the right way around if running on windows
if[.z.o like "w*"; {if["\\" in v:getenv[x]; setenv[x;ssr[v;"\\";"/"]]]} each distinct envvars]

// The variables required to be set in each process
// This is the mimimum set of information that each process must know about itself for registration / advertisement purposes
req:@[value;`req;`symbol$()]
req:distinct `proctype`procname,req

// Dependency Checks
// config.csv to contain app,version,dependency
// dependency formatted "app version" delimited by ;
/- Check each dependency against version number
checkvers:{[i;j;d;t]
    {[i;j;d;t;x]$[("I"$i[x])<"I"$j[x];x:6;("I"$i[x])>"I"$j[x];[.lg.e[`config;(raze/) string t[`app]," ",string t[`version]," requires ",string d," ",sv[".";i],". Current Version is ",string d," ",sv[".";j]];x:6];x+:1]}[i;j;d;t;]/[{x<5};0];}

runchk:{[dict;t;x]
      /- i=dependency. j=version
      j:vs[".";]'[string dict[d:`$first " " vs x]];
      i:"." vs last " " vs x;
      /- check app for current dependency exists
      if[not d in key dict;[.lg.e[`config;(raze/) string t[`app]," ", string t[`version] ," requires ",string d," ",sv[".";i],". Current version not supplied"]]];
      checkvers[i;;d;t]'[j]};

checkdependency:{[path]
      /- check config files are supplied
      if[2<=count path;
        /- check TorQ config file is supplied
        if[()~key hsym last path;[.lg.e[`config;"TorQ config file not supplied ",string last path]]];
        /-load config csv files
        a,:raze {("SSS";enlist ",") 0: hsym[x]} each path;
        /- check for kdb verion
        if[not `kdb in a[`app];a,:(`kdb;`$(string .z.K),".",string .z.k;`)];
        /- get current app versions
        dict:exec version by app from a;
        /- update table to contain string dependencies
        t:update vs[";";]each string dependency from (select from a where dependency<>`);
        /-check each dependency within t
        {[t;dict] runchk[dict;t;]'[t[`dependency]]}[;dict]'[t]]}

getconfig:{[path;level]
        /- check if KDBSERVCONFIG exists
        keyservconf:$[not ""~ksc:getenv`KDBSERVCONFIG;
          key hsym servconf:`$ksc,"/",path;
          ()];
        /- check if KDBAPPCONFIG exists
        keyappconf:$[not ""~kac:getenv`KDBAPPCONFIG;
          key hsym appconf:`$kac,"/",path;
          ()];

        /-if level=2 then all files are returned regardless
        if[level<2;
          if[()~keyappconf;
            appconf:()];
          if[()~keyservconf;
            servconf:()]];

        /-get KDBCONFIG path
        conf:`$(kc:getenv[`KDBCONFIG]),"/",path;

        /-if level is non-zero return appconfig, servconfig and config files
        (),$[level;
          appconf,servconf,conf;
          first appconf,servconf,conf]}

getconfigfile:getconfig[;0]

version:"1.0"
application:""
getversion:{$[0 = count v:@[{raze string exec version from (("SS ";enlist ",")0: x) where app=`TorQ};hsym`$getenv[`KDBCONFIG],"/dependency.csv";version];version;v]}
getapplication:{$[0 = count a:@[{read0 x};hsym last getconfigfile"application.txt";application];application;a]}

\d .lg

// Set the logging table at the top level
// This is to allow it to be published
@[`.;`logmsg;:;([]time:`timestamp$(); sym:`symbol$(); proctype:`symbol$(); host:`symbol$(); loglevel:`symbol$(); id:`symbol$(); message:())]; 

// Logging functions live in here

// Format a log message
format:{[loglevel;proctype;proc;id;message] "|"sv string[(.proc.cp[];.z.h;proctype;proc;loglevel;id)],enlist(),message}

publish:{[loglevel;proctype;proc;id;message]
 if[0<0^pubmap[loglevel];
  // check the publish function exists
  if[@[value;`.ps.initialised;0b];
   .ps.publish[`logmsg;enlist`time`sym`proctype`host`loglevel`id`message!(.proc.cp[];proc;proctype;.z.h;loglevel;id;message)]]]}

// Dictionary of log levels mapped to standard out/err
// Set to 0 if you don't want the log type to print
outmap:@[value;`outmap;`ERROR`ERR`INF`WARN!2 2 1 1]
// whether each message type should be published
pubmap:@[value;`pubmap;`ERROR`ERR`INF`WARN!1 1 0 1]

// Log a message
l:{[loglevel;proctype;proc;id;message;dict]
	if[0 < redir:`int$(0w 1 `onelog in key .proc.params)&0^outmap[loglevel];
		neg[redir] .lg.format[loglevel;proctype;proc;id;message]];
	ext[loglevel;proctype;proc;id;message;dict];
	publish[loglevel;proctype;proc;id;message];	
	}

// Log an error.  
// If the process is fully initialised, throw the error
// If trap mode is set to false, exit
err:{[loglevel;proctype;proc;id;message;dict]
        l[loglevel;proctype;proc;id;message;dict];
        if[.proc.stop;'message];
 	if[.proc.initialised;:()];
        if[not .proc.trap; exit 3];
	}

// log out and log err
// The process name is temporary which we will reset later - once we know what type of process this is
o:l[`INF;`torq;`$"_" sv string (.z.f;.z.i;system"p");;;()!()]
e:err[`ERR;`torq;`$"_" sv string (.z.f;.z.i;system"p");;;()!()]
w:l[`WARN;`torq;`$"_" sv string (.z.f;.z.i;system"p");;;()!()]

// Hook to handle extended logging functionality
// Leave blank
ext:{[loglevel;proctype;proc;id;message;dict]}

banner:{
 width:80;
 format:{"#",(floor[m]#" "),y,((ceiling m:0|.5*x-count y)#" "),"#"}[width - 2];
 blank:"#",((width-2)#" "),"#";
 full:width#"#";
 // print the banner
 -1 full;
 -1 blank; 
 -1 format"TorQ v",.proc.getversion[];
 -1 format"AquaQ Analytics";
 -1 format"kdb+ consultancy, training and support";
 -1 blank;
 -1 format"For questions, comments, requests or bug reports please contact us";
 -1 format"w :     www.aquaq.co.uk";
 -1 format"e : support@aquaq.co.uk";
 -1 blank; 
 -1 format"Running on ","kdb+ ",(string .z.K)," ",string .z.k;
 if[count customtext:.proc.getapplication[];-1 format each customtext;-1 blank]; // prints custom text from file
 -1 full;}

banner[]

// Error functions to check the process is in the correct state when being started
\d .err

// Throw an error and exit
ex:{[id;message;code] .lg.e[id;message]; exit code} 

// Throw an error based on usage
usage:{ex[`usage;.proc.getusage[];1]}

// Throw an error if all the required parameters aren't passed in
param:{[paramdict;reqparams] 
	if[count missing:(reqparams,:()) except key paramdict; 
		.lg.e[`init;"missing required command line parameter(s) "," " sv string missing];
		usage[]]}

// Throw an error if all the requried envinonment variables aren't set
env:{[reqenv]
	if[count missing:reqenv where 0=count each getenv each reqenv,:();
		.lg.e[`init;"required environment variable(s) not set - "," " sv string missing];
		usage[]]}

// Check if a variable is null
exitifnull:{[variable] 
	if[null value variable; 
		.lg.e[`init;"Variable ",(string variable)," is null but must be set"];
		usage[]]}


// Function for replacing environment variables with the associated full path

\d .rmvr

removeenvvar:{
 	// positions of {}
	pos:ss[x]each"{}";
	// check the formatting is ok
	$[0=count first pos; :x;
	1<count distinct count each pos; '"environment variable contains unmatched brackets: ",x;
	(any pos[0]>pos[1]) or any pos[0]<prev pos[1]; '"failed to match environment variable brackets on supplied string: ",x;
	()];

	// cut out each environment variable, and retrieve the meaning
	raze {$["{"=first x;getenv`$1 _ -1 _ x;x]}each (raze flip 0 1+pos) cut x}		
		
// Process initialisation
\d .proc

// Read the process parameters
params:.Q.opt .z.x
// check for a usage flag
if[`usage in key params; -1 .proc.getusage[]; exit 0];

$[`localtime in key .proc.params;
	[cp:{.z.P};cd:{.z.D};ct:{.z.T}];
	[cp:{.z.p};cd:{.z.d};ct:{.z.t}]];

localtime:`localtime in key .proc.params

// Check if we are in fail fast mode
trap:`trap in key params
.lg.o[`init;"trap mode (initialisation errors will be caught and thrown, rather than causing an exit) is set to ",string trap]

// Check if stop mode is set to true
initialised:0b
stop:`stop in key params
.lg.o[`init;"stop mode (initialisation errors cause the process loading to stop) is set to ",string stop]

if[trap and stop; .lg.o[`init;"trap mode and stop mode are both set to true.  Stop mode will take precedence"]];

// Set up the environment if not set
settorqenv'[`KDBCODE`KDBCONFIG`KDBLOG`KDBLIB`KDBHTML;("code";"config";"logs";"lib";"html")];

// Check the environment is set up correctly
.err.env[envvars]

// Need to get some process information for logging / advertisement purposes
// We can either read these from a file, or from the command line
// default should be from a file, but overridden from the cmd line
// The could also be set in a wrapper script
reqset:0b
if[any req in key `.proc;
	$[all req in key `.proc;
		$[any null `.proc req;
			.lg.o[`init;"some of the required process parameters supplied in the  wrapper script are set to null.  All must be set. Resetting all to null"];
			reqset:1b]; 
	  .lg.o[`init;"some but not all required process parameters have been set from the wrapper script - resetting all to null"]]];

if[not reqset; @[`.proc;req;:;`]];

$[count[req] = count req inter key params;
	[@[`.proc;req;:;first each `$params req];
	 reqset:1b];
  0<count req inter key params;
	.lg.o[`init;"ignoring partial subset of required process parameters found on the command line - reading from file"];
  ()];		 

// If parentproctype has been supplied then set it
parentproctype:();
if[`parentproctype in key params;
	parentproctype:first `$params `parentproctype;
	.lg.o[`init;"read in process parameter of parentproctype=",string parentproctype]];

checkdependency[getconfig["dependency.csv";1]]

// If any of the required parameters are null, try to read them from a file
// The file can come from the command line, or from the environment path
file:$[`procfile in key params; 
	first `$params `procfile;
 	first getconfigfile["process.csv"]];

// read the process file and convert port field to integer list and all other fields
// to symbol lists
readprocs:{[file]
	// Updates the process table to convert strings to integer and symbols
	updateprocs:{
		// Gets the value of the input expression and returns it as an integer
		// list if the expression can be evaluated, else return null
		errcheckport:{@[{"I"$string value x};x;0N]};
		
		// begin updating process file table
		t:update port:errcheckport each .rmvr.removeenvvar each port from x;
		t:update host:"S"$.rmvr.removeenvvar each host from t;
		t:update procname:"S"$.rmvr.removeenvvar each procname from t;
		t:update proctype:"S"$.rmvr.removeenvvar each proctype from t;
		// return updated process file table
		t
		};
	// error trap loading and processing of process file and returns finished table
	@[updateprocs ("****";enlist",")0:;file;
	{.lg.e[`procfile;"failed to read process file ",(string x)," : ",y]}[file]]
	}

// Read in the processfile
// Pull out the applicable rows
readprocfile:{[file]
	//order of preference for hostnames
	prefs:(.z.h;`$"." sv string "i"$0x0 vs .z.a;`localhost);
	res:@[{t:select from readprocs[file] where not null host;
	// allow host=localhost for ease of startup
	$[not any null `.proc req;
		select from t where proctype=.proc.proctype,procname=.proc.procname;
		select from t where abs[port]=abs system"p",(lower[host]=lower .z.h) or (host=`localhost) or host=`$"." sv string "i"$0x0 vs .z.a]
		};file;{.err.ex[`init;"failed to read process file ",(string x)," : ",y;2]}[file]];
		if[0=count res;
		.lg.o[`readprocfile;"failed to read any rows from ",(string file)," which relate to this process; Host=",(string .z.h),", IP=",("." sv string "i"$0x0 vs .z.a),", port=",string system"p"];
		:`host`port`proctype`procname!(`;0;proctype;procname)];
		// if more than one result, take the most preferred one
	output:$[1<count res;
		// map hostnames in res to order of preference, select most preferred
		first res iasc prefs?res[`host];
		first res];
        if[not output[`host]in prefs;
                .err.ex[`readprocfile;"Current host does not match host specified in ",string[file],". Parameters are host: ", string[output`host], ", port: ", string[output`port], ", proctype: ", string[output`proctype], ", procname: ",string output`procname;1]];
	// exit if no port passed via command line or specified in config
	if[null[output`port]&0i=system"p";
		.err.ex[`readprocfile;"No port passed via -p flag or found in ",string[file],". Parameters are host: ", string[output`host], ", proctype: ", string[output`proctype], ", procname: ",string output`procname;1]]; 
	if[not[output[`port] = system"p"]& 0i = system"p";
		@[system;"p ",string[output[`port]];.err.ex[`readprocfile;"failed to set port to ",string[output[`port]]]];
		.lg.o[`readprocfile;"port set to ",string[output[`port]]]
		];
	output
	}	

.lg.o[`init;"attempting to read required process parameters ",("," sv string req)," from file ",string file];
// Read in the file, pull out the rows which are applicable and set the local variables
{@[`.proc;y;:;x y]}[readprocfile[file];req];

// Check if all the required variables have now been set properly
$[any null `.proc req;
	.err.ex[`init;"not all required variables have been set - missing ",(" " sv string req where null `.proc req);2];	
	.lg.o[`init;"read in process parameters of ","; " sv "=" sv' string flip(req;`.proc req)]]

// reset the logging functions to now use the name of the process
.lg.o:.lg.l[`INF;proctype;procname;;;()!()]
.lg.e:.lg.err[`ERR;proctype;procname;;;()!()]
.lg.w:.lg.l[`WARN;proctype;procname;;;()!()]

// redirect std out or std err to a file
// if alias is not null, a softlink will be created back to the actual file
// handle can either be 1 or 2
fileredirect:{[logdir;filename;alias;handle]
	if[not (h:string handle) in (enlist "1";enlist "2"); 
		'"handle must be 1 or 2"];
	.lg.o[`logging;"re-directing ",h," to",f:" ",logdir,"/",filename];
	@[system;s;{.lg.e[`logging;"failed to redirect ",x," : ",y]}[s:h,f]];
	if[not null `$alias; createalias[logdir;filename;alias]]}

createalias:{[logdir;filename;alias] 
	$[.z.o like "w*"; 
  		.lg.o[`logging;"cannot create alias on windows OS"];
 		[.lg.o[`logging;"creating alias using command ",s:"ln -sf ",filename," ",logdir,"/",alias];
		 @[system;s;{.lg.e[`init;"failed to create alias ",x," : ",y]}[s]]]]}

// Create log files
// logname = base of log file
// timestamp = optional timestamp value (e.g. .z.d, .z.p)
// makealias = if true, will create alias files without the timestamp value
createlog:{[logdir;logname;timestamp;suppressalias]
	basename:(string logname),"_",(string timestamp),".log";
	alias:$[suppressalias;"";(string logname),".log"];
	fileredirect[logdir;"err_",basename;"err_",alias;2];
	fileredirect[logdir;"out_",basename;"out_",alias;1];
	.lg.banner[]}

// function to produce the timestamp value for the log file
logtimestamp:@[value;`logtimestamp;{[x] {[]`$ssr[;;"_"]/[string .z.z;".:T"]}}]

rolllogauto:{[] 
	.lg.o[`logging;"creating standard out and standard err logs"];
	createlog[getenv`KDBLOG;procname;logtimestamp[];`suppressalias in key params]}

// Create log files as long as they haven't been switched off 
if[not any `debug`noredirect in key params; rolllogauto[]];

// utilities to load individual files / paths, and also a complete directory
// this should then be enough to bootstrap
loadedf:enlist enlist""
loadf0:{[reload;x]
  if[not[reload]&x in loadedf;.lg.o[`fileload;"already loaded ",x];:()];
  .lg.o[`fileload;"loading ",x];
  // error trapped loading of file
  @[system;"l ",x;{.lg.e[`fileload;"failed to load",x," : ",y]}[x]];
  // if we got this far, file is loaded
  loadedf,:enlist x;
  .lg.o[`fileload;"successfully loaded ",x]
 }
loadf:loadf0[0b]   /load a file if it hasn't been loaded
reloadf:loadf0[1b] /load a file even if's been loaded

loaddir:{
	.lg.o[`fileload;"loading q and k files from directory ",x];
	// Check the directory exists
	$[()~files:key hsym `$x; .lg.o[`fileload;"specified directory ",x," doesn't exist"];
	// Try to read in a load order file
		[
        	$[`order.txt in files:key hsym `$x;
                	[.lg.o[`fileload;"found load order file order.txt"];
                 	order:(`$read0 `$x,"/order.txt") inter files;
                 	.lg.o[`fileload;"loading files in order "," " sv string order]];
                	order:`symbol$()];
        	files:files where any files like/: ("*.q";"*.k");
        	// rearrange the ordering
        	files:order,files except order;
        	loadf each (x,"/"),/:string files
		]
	];
	}

// load a config file
loadconfig:{
	file:x,(string y),".q";
	$[()~key hsym`$file;
		.lg.o[`fileload;"config file ",file," not found"];
		[.lg.o[`fileload;"config file ",file," found"];
		 loadf file]]}

// Get the attributes of this process.  This should be overridden for each process
getattributes:{()!()}

// override config variables with parameters from the commandline
overrideconfig:{[params]
	// work out which are the potential variables to override
	ov:key[params] where key[params] like ".*";
	// can only can do those which are already set 
	ov:ov where @[{value x;1b};;0b] each ov;
	if[count ov;
		.lg.o[`init;"attempting to override variables ",("," sv string ov)," from the command line"];
		{if[not (abs t:type value y) within (1;-1+count .Q.t);
			.lg.e[`init;"Cannot override ",(string y)," as it is not a basic type"];
			:()];
		 // parse out the values 
		 vals:(upper .Q.t abs t)$'x[y];
		 if[t<0;vals:first vals];
		 // check for nulls
		 if[any null each vals; .lg.e[`init;"Cannot override ",(string y)," with command line parameters as null values have been supplied"]];
		 .lg.o[`init;"Setting ",(string y)," to ",-3!vals];
		 set[y;vals]}[params] each ov]}	

override:{overrideconfig[.proc.params]}

loadspeccode:{[ext;dir]
	$[""~getenv dir;
	 .lg.o[`init;"Environment variable ",string[dir]," not set, not loading specific ",ext," code"];
	 loaddir getenv[dir],ext
   ];
	};

reloadcommoncode:{
	// Load common code from each directory if it exists
	loadspeccode["/common"]'[`KDBCODE`KDBSERVCODE`KDBAPPCODE];
	};
reloadparentprocesscode:{
	// Load parentproctype code from each directory if it exists
	loadspeccode["/",string parentproctype]'[`KDBCODE`KDBSERVCODE`KDBAPPCODE];
	};
reloadprocesscode:{
	// Load proctype code from each directory if it exists
	loadspeccode["/",string proctype]'[`KDBCODE`KDBSERVCODE`KDBAPPCODE];
	};
reloadnamecode:{
	// Load procname code from each directory if it exists
	loadspeccode["/",string procname]'[`KDBCODE`KDBSERVCODE`KDBAPPCODE];
	};

\d . 
// Load configuration
// TorQ loads configuration modules in the order: TorQ Default, Service Specific and then Application Specific
// Each module loads configuration in the order: default configuration, then process type specific, then process specific
if[not `noconfig in key .proc.params;
	// load TorQ Default configuration module
	.proc.loadconfig[getenv[`KDBCONFIG],"/settings/";] each `default,.proc.parentproctype,.proc.proctype,.proc.procname;
  // check if KDBSERVCONFIG is set and load Service Layer specific configuration module
  $[""~getenv`KDBSERVCONFIG;
    .lg.o[`fileload;"environment variable KDBSERVCONFIG not set, not loading app specific config"];
    [.proc.servconfig:getenv[`KDBSERVCONFIG],"/settings/";
    .lg.o[`fileload;"environment variable KDBSERVCONFIG set, loading app specific config from ",.proc.servconfig];
    .proc.loadconfig[.proc.servconfig;] each `default,.proc.parentproctype,.proc.proctype,.proc.procname]
  ];
	// check if KDBAPPCONFIG is set and load Appliation specific configuration module 
  $[""~getenv`KDBAPPCONFIG;	
	  .lg.o[`fileload;"environment variable KDBAPPCONFIG not set, not loading app specific config"];
	  [.proc.appconfig:getenv[`KDBAPPCONFIG],"/settings/";
	  .lg.o[`fileload;"environment variable KDBAPPCONFIG set, loading app specific config from ",.proc.appconfig];
	  .proc.loadconfig[.proc.appconfig;] each `default,.proc.parentproctype,.proc.proctype,.proc.procname]
  ];
	// Override config from the command line
	.proc.override[]]

// Load library code 
.proc.loadcommoncode:@[value;`.proc.loadcommoncode;1b];
.proc.loadprocesscode:@[value;`.proc.loadprocesscode;1b];
.proc.loadnamecode:@[value;`.proc.loadnamecode;0b];
.proc.loadhandlers:@[value;`.proc.loadhandlers;1b];
.proc.logroll:@[value;`.proc.logroll;1]
.lg.o[`init;".proc.loadcommoncode flag set to ",string .proc.loadcommoncode];
.lg.o[`init;".proc.loadprocesscode flag set to ",string .proc.loadprocesscode];
.lg.o[`init;".proc.loadnamecode flag set to ",string .proc.loadnamecode];
.lg.o[`init;".proc.loadhandlers flag set to ",string .proc.loadhandlers];
.lg.o[`init;".proc.logroll flag set to ",string .proc.logroll];

.proc.reloadallcode:{
	if[.proc.loadcommoncode; .proc.reloadcommoncode[]];
	if[.proc.loadprocesscode & not null first `symbol$.proc.parentproctype;.proc.reloadparentprocesscode[]];
	if[.proc.loadprocesscode;.proc.reloadprocesscode[]];
	if[.proc.loadnamecode;.proc.reloadnamecode[]];
	};
.proc.reloadallcode[];

if[`loaddir in key .proc.params;
	.lg.o[`init;"loaddir flag found - loading files in directory ",first .proc.params`loaddir];
	.proc.loaddir each .proc.params`loaddir]

// Load message handlers after all the other library code
.proc.loaddir each(getenv$[.proc.loadhandlers & not ""~getenv`KDBSERVCODE;`KDBCODE`KDBSERVCODE;(),`KDBCODE]),\:"/handlers";

// If the timer is loaded, and logrolling is set to true, try to log the roll file on a daily basis
if[.proc.logroll and not any `debug`noredirect in key .proc.params;
	$[@[value;`.timer.enabled;0b];
		[.lg.o[`init;"adding timer function to roll std out/err logs on a daily schedule starting at ",string `timestamp$(.proc.cd[]+1)+00:00];
		 .timer.rep[`timestamp$.proc.cd[]+00:00;0Wp;1D;(`.proc.rolllogauto;`);0h;"roll standard out/standard error logs";1b]];
		.lg.e[`init;".proc.logroll is set to true, but timer functionality is not loaded - cannot roll logs"]]];
	
// Load the file specified on the command line
if[`load in key .proc.params; .proc.reloadf each .proc.params`load]

if[any`debug`nopi in key .proc.params;
	.lg.o[`init;"Resetting .z.pi to kdb+ default value"];
	.z.pi:{.Q.s value x};]

// initialise pubsub
if[@[value;`.ps.loaded;0b]; .ps.initialise[]]
// initialise connections
if[@[value;`.servers.STARTUP;0b]; .servers.startup[]]

// function to execute functions in .proc.initlist
.proc.try:{[id;a]
  .lg.o[id;"attempting to run: ",.Q.s1 a];
  success:@[{value x;1b};a;{[id;a;x].lg.e[id;x," error - failed to run: ",.Q.s1 a];0b}[id;a]];
  if[not success;:()];
  .proc.initexecuted,:a;
  .lg.o[id;"run successful: ",.Q.s1 a];
 }

.proc.initcmd:{
  // command line functions executed first
  if[not`initlist in key .proc.params;:.lg.o[`init;"no initialisation functions found in cmd line args"]];
  {.proc.try[`init;(x;`)]}each .proc.params`initlist;
 }

.proc.init:{
  .proc.initcmd[];
  if[0=count .proc.initlist;:.lg.o[`init;"no initialisation functions found"]];
  .proc.try[`init]each .proc.initlist;
  .proc.initlist:();
 }

if[count .proc.initlist;.proc.init[]]

.lg.banner[]

// set the initialised flag
.proc.initialised:1b

// set start time of the process
.proc.starttimeUTC:.z.p

if[`test in key .proc.params;
        $[0<count[getenv[`KDBTESTS]];
                .proc.loaddir getenv[`KDBTESTS];
                .lg.e[`init;"environment variable KDBTESTS undefined"]]
        ]
