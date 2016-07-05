/ - this scrip contains the code which is used to apply data manipulation at save down, sort and apply attributes to data and garbage collect
/ - typically used by the TorQ process that persist data to disk e.g. rdb, tickerlogreplay, wdb, ...

\d .sort

/ - create an initial .sort.params table (this will be populated later by the getsortcsv function)
params:([] tabname:`symbol$(); att:`symbol$(); column:`symbol$(); sort:`boolean$());

/ - setting default location for the sort csv file
/ - will be used if there is a null parameter passed to the getsortcsv function
defaultfile:first .proc.getconfigfile["sort.csv"];

/ - this function is used to retrieve and parse the contents of the sort.csv file
/ - some validation is performed and the sort parameters are sorted in a global variable called
/ - .sort.params
getsortcsv:{[file]
	file: hsym file;
	if[null file; file:defaultfile];
	params:@[
            {.lg.o[`init;"retrieving sort settings from ",string x];("SSSB";enlist",")0: x};
            file; 
            {[x;e] '"failed to open ",string[x],". The error was : ",e ;}[file]
        ];
	/-check the correct columns have been included in csv file
	if[not all spcb: (spc: cols params) in `tabname`att`column`sort;
            '"unrecognised columns (",(", " sv string spc where not spcb),") in ", string file];
	/-check that attributes are acceptable
	if[not all atb: (at:distinct params`att) in ``p`s`g`u;'"unrecognised type of attribute - ",", " sv string at where not atb];
	/-set sortparams globally
	@[`.sort;`params;:;params];
	};
	
/ - this is main sort function that will be called of each table to be sorted
/-function to reload, sort and save tables 
/- this function can be passed a table name of a pair of (tablename;table directory(s))
sorttab:{[d]
    // try to read in the sort configuration from the default location
    if[0=count params; getsortcsv defaultfile];
    .lg.o[`sort;"sorting the ",(st:string t:first d)," table"];
	/ - get the sort configuration	
	sp:$[count tabsortparams:select from params where tabname=t;
			[.lg.o[`sorttab;"Sort parameters have been retrieved for : ",st];tabsortparams];
		count defaultsortparams:select from params where tabname=`default;
			[.lg.o[`sorttab;"No sort parameters have been specified for : ",st,". Using default parameters"];defaultsortparams];
		/ - else escape, no sort params have been specified
			[.lg.o[`sorttab;"No sort parameters have been found for this table (",st,").  The table will not be sorted"];:()]];
	/ - loop through for each directory
	{[sp;dloc] / - sort the data 
		if[count sortcols: exec column from sp where sort, not null column;
			.lg.o[`sortfunction;"sorting ",string[dloc]," by these columns : ",", " sv string sortcols]; 
			.[xasc;(sortcols;dloc);{[sortcols;dloc;e] .lg.e[`sortfunction;"failed to sort ",string[dloc]," by these columns : ",(", " sv string sortcols),".  The error was: ",e]}[sortcols;dloc]]];
		if[count attrcols: select column, att from sp where not null att;
			/-apply attribute(s)
			applyattr[dloc;;]'[attrcols`column;attrcols`att]];
	}[sp] each distinct (),last d;
	.lg.o[`sort;"finished sorting the ",st," table"];
	};
	
/-function to apply attributes to columns
applyattr:{[dloc;colname;att]
	.lg.o[`applyattr;"applying ",string[att]," attr to the ",string[colname]," column in ",string dloc];
	/ - attempt to apply the attribute to the column and log an error if it fails
	.[{@[x;y;z#]};(dloc;colname;att);
		{[dloc;colname;att;e] .lg.e[`applyattr;"unable to apply ",string[att]," attr to the ",string[colname]," column in the this directory : ",string[dloc],". The error was : ",e];}[dloc;colname;att]
	]
	};
	
/ - these functions are common across the TorQ processes that persist save to the data base
\d .save

/ - define a default dictionary of manipulation functions to apply of tables before it is enumerated an persisted to disk
savedownmanipulation:()!();

/- manipulate a table at save down time
manipulate:{[t;x] 
 $[t in key savedownmanipulation; 
  @[savedownmanipulation[t];x;{.lg.e[`manipulate;"save down manipulation failed : ",y];x}[x]];
  x]};

/- post eod/replay, this is called after the date has been persisted to disk and sorted and 
/- takes a directory (typically hdb directory) and partition value as parameters
postreplay:{[d;p]		
	
	};
	
/ - functions for running and descriptively logging garbage collection
\d .gc

/ - format the process memory stat's into a string for logging
memstats:{"mem stats: ",{"; "sv "=" sv'flip (string key x;(string value x),\:" MB")}`long$.Q.w[]%1048576}

/ - run garbage collection and log out memory stats
run:{
  .lg.o[`garbagecollect;"Starting garbage collect. ",memstats[]];
  r:.Q.gc[];
  .lg.o[`garbagecollect;"Garbage collection returned ",(string `long$r%1048576),"MB. ",memstats[]]}
