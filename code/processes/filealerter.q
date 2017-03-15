//File-alerter
//Andrew Steele. andrew.steele@aquaq.co.uk
//AQUAQ Analytics Info@aquaq.co.uk +4402890511232

inputcsv:@[value;`.fa.inputcsv;.proc.getconfigfile["filealerter.csv"]]		// The name of the input csv to drive what gets done
polltime:@[value;`.fa.polltime;0D00:00:10]							// The period to poll the file system
alreadyprocessed:@[value;`.fa.alreadyprocessed;.proc.getconfigfile["filealerterprocessed"]]	// The location of the table on disk to store the information about files which have already been processed
skipallonstart:@[value;`.fa.skipallonstart;0b]							// Whether to skip all actions when the file alerter process starts up (so only "new" files after the processes starts will be processed) 
moveonfail:@[value;`.fa.moveonfail;0b]								// If the processing of a file fails (by any action) then whether to move it or not regardless
os:$[like[string .z.o;"w*"];`win;`lin]
usemd5:@[value; `.fa.usemd5; 1b]								// Protected evaluation, returns value of usemd5 (from .fa namespace) or on fail, returns 1b

inputcsv:string inputcsv
alreadyprocessed:string alreadyprocessed

//-function to load the config csv file
csvloader:{[CSV]  
	fullcsv:@[{.lg.o[`alerter;"opening ",x];("**SB*"; enlist ",") 0: hsym `$x};CSV;{.lg.e[`alerter;"failed to open",x," : ", y];'y}[CSV]];
	check:all `path`match`function`newonly`movetodirectory in cols fullcsv;
	$[check=0b;
		[.lg.e[`alerter;"the file ",CSV," has incorrect layout"]];
		.lg.o[`alerter;"successfully loaded ",CSV]];
	/-Removing any null rows from the table
	nullrows:select from fullcsv where (0=count each path)|(0=count each match)|(null function);
	if[0<count nullrows; .lg.o[`alerter;"null rows were found in the csv file: they will be ignored"]];
	filealertercsv::fullcsv except nullrows;
	if[os=`win;
		.lg.o[`alerter;"modifying file-paths to a Windows-friendly format"]; 
		update path:ssr'[path;"/";"\\"],movetodirectory:ssr'[movetodirectory;"/";"\\"] from `filealertercsv];
	}

//-function to load the alreadyprocessed table or initialise a processed table if skipallonstart is enabled
loadprocessed:{[BIN] 
	.lg.o[`alerter;"loading alreadyprocessed table from ",alreadyprocessed];
	splaytables[BIN];
	if[skipallonstart;.lg.o[`alerter;"variable skipallonstart set to true"];skipall[]]}

//-searches for files on a given path matching the search string
find:{[path;match]
	findstring:$[os=`lin;"/usr/bin/find ", path," -maxdepth 1 -type f -name \"",match,"\"";"dir ",path,"\\",match, " /B 2>nul"];
	.lg.o[`alerter;"searching for ",path,"/",match];
	files:@[system;findstring;()];
	if[os=`win;files:,/:[path,"\\"; files]]; files};
	
	
//-finds all matches to files in the csv and adds them to the already processed table	
skipall:{matches:raze find'[filealertercsv.path;filealertercsv.match];
	.lg.o[`alerter;"found ",(string count matches)," files, but ignoring them"]; complete removeprocessed[matches]}



//-runs the function on the file	
action:{[function;file]	
	$[`nothere~@[value;function;`nothere];
		{.lg.e[`alerter;"function ", (string x)," has not been defined"]}'[function];
		.[{.lg.o[`alerter;"running function ",(string x)," on ",y];((value x)[getpath[y];getfile[y]]);:1b};
			(function;file);
			{.lg.e[`alerter;"failed to execute ", (string x)," on ",y,": ", z]; ();:0b}[function;file]]]}
					

//-adds the processed file, along with md5 hash and file size to the already processed table and saves it to disk
complete:{[TAB]
  TAB:select filename, md5hash, filesize from TAB;
  if[count TAB;
        .lg.o[`alerter;"adding ",(" " sv TAB`filename)," to alreadyprocessed table"];

  // write it to disk
  .lg.o[`alerter;"saving alreadyprocessed table to disk"];
  .[insert;(hsym`$alreadyprocessed;TAB);{.lg.e[`alerter;"failed to save alreadyprocessed table to disk: ",x]}]];
 }

//-check files against alreadyprocessed, remove those which have been processed (called in getunprocessed)
removeprocessed:{[files] x:chktable[files];
        y:select from (get hsym`$alreadyprocessed) where filesize in (exec filesize from x);
        $[usemd5;x except y;x where not (select filename,filesize from x) in select filename,filesize from y]}

//-discard processed files: if newonly is False match only on filename
getunprocessed:{[matches;newonly] $[newonly;chktable[matches except exec filename from get hsym`$alreadyprocessed];removeprocessed[matches]]}




//-Some utility functions
getsize:{hcount hsym `$x}
gethash:{[file] $[os=`lin;
        md5hash:@[{first " " vs raze system "md5sum ",x," 2>/dev/null"};file;{.lg.e[`alerter;"could not compute md5 on ",x,": ",y];""}[file]];
        ""]}
getfile:{[filestring] $[os=`lin;last "/" vs filestring;last "\\" vs filestring]}
getpath:{[filestring] (neg count getfile[filestring]) _filestring}
//-Create table of filename,md5hash,filesize (only compute md5hash if usemd5 is True)
chktable:{[files] table:([]filename:files;md5hash:$[usemd5;gethash'[files];(count files)#enlist ""];filesize:getsize'[files])}
	

//-The main function that brings everything together
processfiles:{[DICT]
        /-find all matches to the file search string
        matches:find[.rmvr.removeenvvar[DICT[`path]];DICT[`match]];
        toprocess:getunprocessed[matches;DICT[`newonly]];
        files:exec filename from toprocess;
        /-If there are files to process
        $[0<count files;
        [{.lg.o[`alerter;"found file ", x]}'[files];
        /-perform the function on the file
        pf:action/:[DICT[`function];files];];
        .lg.o[`alerter;"no new files found"]];
        t:update function:(count toprocess)#DICT[`function],funcpassed:pf,moveto:(count toprocess)#enlist .rmvr.removeenvvar[DICT[`movetodirectory]] from toprocess; t}



//-function to move files in a table, first col is files second col is destination	
moveall:{[TAB]
	/-don't attempt to move any file that are not there, e.g. if the file was already moved during process
	tomove:delete from TAB where 0=count each key each hsym `$TAB[`filename];
	/-only attempt to move distinct values in the table
	tomove:distinct tomove;
	/-if the move-to directory is null, do not move the file
	tomove:delete from tomove where 0=count each moveto;
	/-error check that a file does not have two different move-to paths
	errors:exec filename from (select n:count distinct moveto by filename from tomove) where n>1;
	if[0<count errors;{.lg.e[`alerter;"file ",x," has two differnt move-to directories in the csv:it will not be moved"]} each errors];
	tomove:delete from tomove where filename in errors;
	movefile each tomove;}
		
movefile:{[DICT]
	.lg.o[`alerter;"moving ",DICT[`filename]," to ",DICT[`moveto]];
	@[system;
		"r ",DICT[`filename]," ",DICT[`moveto],"/",getfile[DICT[`filename]];
		{.lg.e[`alerter;"could not move file ",x, ": ",y]}[DICT[`filename]]]}

loadcsv:{csvloader inputcsv}
FArun:{.lg.o[`alerter;"running filealerter process"];
		$[0=count filealertercsv;
		.lg.o[`alerter;"csv file is empty"];
		[lastproc:raze processfiles each filealertercsv;
                      newproc:select filename,md5hash,filesize,moveto from lastproc;
                      $[moveonfail;
				successful:newproc;
				successful:select filename,md5hash,filesize,moveto from lastproc where (all;funcpassed=1b) fby filename];
			complete newproc;
			moveall[successful]]];
	}

splaytables:{[BIN]
    FILE_PATH: hsym `$BIN;			 				//create file path symbol

	// table doesnt exist
	// create a splayed table on disk
	if[0 = count key FILE_PATH;.lg.o[`alerter;"no table found, creating new table"];
	.Q.dd[FILE_PATH;`] set ([] filename:();md5hash:(); filesize:`long$())];

	//table does exist
	//if it is flat (1)- cast md5hash symbols to string (where applicable) and splay it
	$[-11h ~ type key FILE_PATH;
		[FILE_PATH_BK: `$(string FILE_PATH),"_bk"; 										//create backup file path symbol
		.lg.o[`alerter;"flat table found: ",string FILE_PATH];
		.lg.o[`alerter;"creating backup of flatfile : ", string FILE_PATH_BK];
		.os.cpy[FILE_PATH;FILE_PATH_BK];												//create _bk of file
		.lg.o[`alerter;"removing original flatfile: ", string FILE_PATH];
		hdel FILE_PATH;																	//delete original file
		.lg.o[`alerter;"creating new splayed table: ", string .Q.dd[FILE_PATH;`]];
			
		//if md5hash is symbol set it to string else just splay
		.[set;(.Q.dd[FILE_PATH;`];$[11h ~ type exec md5hash from get FILE_PATH_BK; update string md5hash from (get FILE_PATH_BK); get FILE_PATH_BK]);{.lg.e[`alerter;"failed to write",x]}];	//cast md5 to string and splay table
		];					
		//else splayed table found
		[.lg.o[`alerter;"splayed table found: ",string FILE_PATH];]
		];
	}

loadcsv[];
loadprocessed[alreadyprocessed];

.timer.rep[.proc.cp[];0Wp;polltime;(`FArun`);0h;"run filealerter";1b]
