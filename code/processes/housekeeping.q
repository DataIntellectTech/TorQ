//Housekeeping
//Tobias Harper. tobias.harper@aquaq.co.uk
//AQUAQ Analytics Info@aquaq.co.uk +4402890511232

/-variables
inputcsv:@[value;`.hk.inputcsv;.proc.getconfigfile["housekeeping.csv"]]
runtimes:@[value;`.hk.runtimes;12:00]
runnow:@[value;`.hk.runnow;0b]
.win.version:@[value;`.win.version;`w10]

inputcsv:string inputcsv

/- set up the usage information
.hk.extrausage: "Housekeeping:\n 
	This process is used to remove and zip files older than certain date.
	The process is designed to be extended through user defined functions added to this script.
	Calling hkrun[] will run the service immediately.
	The process can be set on a timer from the times in the config file.
	The process runs from a csv, the location of which can be set in the config file.
	Housekeeping reads in from a file that has headers;
	\n
	[function]\t\t\t\trm for remove zip for gzip 
	[path]\t\t\t\t\tdirectory to files
	[match]\t\t\t\tstring to match
	[exclude]\t\t\t\tstring to exclude from matched selection
	[age]\t\t\t\t\tage of files (days) you wish to match
	\n
	There are some config options which can be set via the standard command line switches e.g. -runnow
	\n 

	[-hkusage]\t\t\t\tShow usage information 
	[-.hk.inputcsv x]\t\t\tThe directory of the housekeeping CSV folder. If null, config/housekeeping.csv is used
	[-.hk.runtimes]\t\t\tThe time you wish to schedule housekeeping. Defaults to 12:00
	[-.hk.runnow]\t\t\t\tRun the housekeeping process and exit
	\n
	The behaviour upon encountering errors can be modified using the standard flags. With no flags set, the process will exit when it hits an error. 
	To trap an error and carry on, use the -trap flag
	To stop at error and not exit, use the -stop flag
	"
//using the -hkusage tag in command line dumps info
if[`hkusage in key .proc.params; -1 .hk.extrausage; exit 0]

//-defines housekeeping
csvloader:{[CSV]
//-rethrows error if file doesn't exist, checks to see if correct columns exist in file
	housekeepingcsv::@[{.lg.o[`housekeeping;"Opening ",x];("S***IB"; enlist ",") 0:"S"$x};CSV;{.lg.e[`housekeeping;"failed to open ",x," : ", y];'y}[CSV]];
	housekeepingcsv::@[c;where (c:cols housekeepingcsv) in ``x;:;`agemin] xcol housekeepingcsv;
	check:(all `function`path`match`exclude`age`agemin in (cols housekeepingcsv));
	//-if check shows incorrect columns, report error
	$[check~0b; [{.lg.e[`housekeeping;"The file ",x," has incorrect layout"];'`$"incorrect housekeeping csv layout"}[CSV]];
		//-if correctly columned csv has nulls, report error and skip lines 
		[if[(any nullcheck:any null (housekeepingcsv.function;housekeepingcsv.age))>0; .lg.o[`housekeeping;"Null values found in file, skipping line(s)  ", ("," sv (string where nullcheck))]];
		housekeepingcsv2:(housekeepingcsv[where not nullcheck]);
			wrapper each housekeepingcsv2]]}


//-Sees if the function in the CSV file is in the function list. if so- it carries out that function on files that match the parameters in the csv [using find function]
wrapper:{[DICT]
	$[not DICT[`function] in key `.;.lg.e[`housekeeping;"Could not find function: ",string DICT[`function]];
	(value DICT[`function]) each (find[.rmvr.removeenvvar [DICT[`path]];DICT[`match];DICT[`age];DICT[`agemin]] except find[.rmvr.removeenvvar [DICT[`path]];DICT[`exclude];DICT[`age];DICT[`agemin]])]}



//compress by calling .cmp.compress function defined using -19!
kdbzip:{[FILE]   
	 @[{.lg.o[`housekeeping;"compressing ",x]; .cmp.compress[filehandles;2;17;4;hcount filehandles:hsym `$x]};
	     FILE; 
	 {.lg.e[`housekeeping;"Failed to compress ",x," : ", y]}[FILE]] 
	  }



//FUNCTIONS FOR LINUX
\d .unix

//-locates files with path, matching string and age
find:{[path;match;age;agemin]
	$[0=agemin;
	files:.[{.lg.o[`housekeeping;"Searching for: ",x,y];system "/usr/bin/find ", x," -maxdepth 1 -type f -name \"",y,"\" -mtime +",raze string z};(path;match;age);
	{.lg.e[`housekeeping;"Find function failed: ", x]; ()}];
	 files:.[{.lg.o[`housekeeping;"Searching for: ",x,y];system "/usr/bin/find ", x," -maxdepth 1 -type f -name \"",y,"\" -mmin +",raze string z};(path;match;age);
	{.lg.e[`housekeeping;"Find function failed: ", x]; ()}]];
	$[(count files)=0;[.lg.o[`housekeeping;"No matching files located"];files]; files]}


//-removes files
rm:{[FILE]
	@[{.lg.o[`housekeeping;"removing ",x]; system "rm -f ",x};FILE; {.lg.e[`housekeeping;"Failed to remove ",x," : ", y]}[FILE]]}


//-zips files
zip:{[FILE]
	@[{.lg.o[`housekeeping;"zipping ",x]; system "gzip ",x};FILE; {.lg.e[`housekeeping;"Failed to zip ",x," : ", y]}[FILE]]}
\d .
//FUNCTIONS FOR WINDOWS
\d .win

//-locates files with path, matching string and age
find:{[path;match;age;agemin]
	//returns empty list for files if match is an empty string
        if[""~match;
          .lg.o[`housekeeping;"No matching files located"];
          :();
        ];
	//renames the path to a windows readable format
	PATH:ssr[path;"/";"\\"];
	//error and info for find function 
	err:{.lg.e[`housekeeping;"Find function failed: ", x]; ()};
        //searches for files and refines return to usable format
	$[0=agemin;
	files:.[{[PATH;match;age].lg.o[`housekeeping;"Searching for: ", match];
		system "z 1";fulllist:winfilelist[PATH;match];
		removelist:fulllist where ("D"${10#x} each fulllist)<.proc.cd[]-age; system "z 0";
		{[path;x]path,last " " vs x} [PATH;] each removelist};(PATH;match;age);err];
	files:.[{[PATH;match;age].lg.o[`housekeeping;"Searching for: ", match];
		system "z 1";fulllist:winfilelist[PATH;match];
		removelist:fulllist where ({ts:("  " vs 17#x);("D"$ts[0]) + value ts[1]} each fulllist)<.proc.cp[]-`minute$age; system "z 0";
		{[path;x]path,last " " vs x} [PATH;] each removelist};(PATH;match;age);err]];
	$[(count files)=0;
	[.lg.o[`housekeeping;"No matching files located"];files]; files]}

//defines full list of files based on Windows OS version
winfilelist:{[path;match]
	$[version in `w7`w8`w10;-2_(5_system "dir ",path,match);-5_(5_system "dir ",path,match, " /s")]
 }


//removes files
rm: {[FILE]
	@[{.lg.o[`housekeeping;"removing ",x];system"del /F /Q ", x};FILE;{.lg.e[`housekeeping;"Failed to remove ",x," : ", y]}[FILE]]}

//zips files NYI
zip:{[FILE]
	.lg.e[`housekeeping;"zipping nyi for file ",FILE]}

\d .

$[.z.o like "w*";[find:.win.find; rm:.win.rm;zip:.win.zip;];[find:.unix.find; rm:.unix.rm;zip:.unix.zip;]]

//-runner function
hkrun:{[]
	csvloader inputcsv}

$[runnow=1b;[hkrun[];exit 0];]

//-sets timers occording to csv
$[(count runtimes)=0;
	.lg.e[`housekeeping;"No runtimes provided in config file"];
	[{[runtime].timer.rep[$[.proc.cp[]>.proc.cd[]+runtime;1D+`timestamp$.proc.cd[]+runtime;`timestamp$.proc.cd[]+runtime];0Wp;1D;(`hkrun`);0h;"run housekeeping";0b]} each runtimes;.lg.o[`housekeeping;"Housekeeping scheduled for: ", (" " sv string raze runtimes)]]]


