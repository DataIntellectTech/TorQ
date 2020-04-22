// A generic dataloader library
// generalisation of http://code.kx.com/wiki/Cookbook/LoadingFromLargeFiles
// will read in a directory of input files and write them out to an HDB
// files are read in chunks using .Q.fsn
// main function to call is loadallfiles
// loadallfiles takes a directory of files to read, and a dictionary

// headers = names of headers in the file e.g. `sym`time`price`size`condition
// types = data types e.g. "SPFIC"
// separator = separator field.  enlist it if the first row in the file is header data (same as standard q way) e.g. enlist","
// tablename = name of table to load to, e.g. `trade
// dbdir = database directory to write to e.g. `:hdb
// symdir [optional] = directory to enumerate against; default is to enumerate against dbdir
// dataprocessfunc [optional] = diadic function to use to further process data before saving. 
// Parameters passed in are loadparams dict and data to be modified.  Default is {[x;y] y}
// partitiontype [optional] = the partition type - one of `date`month`year`int.  Default is `date
// partitioncol [optional] = the name of the column to cast to the partition type to work out which partition the data should go in.  default is `time
// chunksize [optional] = size of data chunks in bytes to read at a time.  default is 100MB
// compression [optional] = compression parameters to use. list of 3 integers e.g. 17 2 6.
// filepattern [optional] = specify pattern used to filter files
// These are only set when the data is sorted on disk (in the finish function) to save on writing the data compressed, reading in and uncompressing, sorting, and writing out compressed again
// gc [optional] = boolean flag to turn garbage collection on and off.  Default is 0b

// e.g. 
// .loader.loadallfiles[`headers`types`separator`tablename`dbdir!(`sym`time`price`volume`mktflag`cond`exclude;"SPFICHB";",";`tdc;`:hdb); `:TDC/toload]

\d .loader

// maintain a dictionary of the db partitions which have been written to by the loader
partitions:()!()

// maintain a list of files which have been read
filesread:()

// loader function
loaddata:{[loadparams;rawdata]

 .lg.o[`dataloader;"reading in data chunk"];
 
 // check if we have already read some data from this file
 // if this is the first time we've seen it, then the first row
 // may contain the header information
 // in both cases we want to return a table with the same column names
 data:$[not loadparams[`filename] in filesread;
	   // it hasn't been seen - the first row may or may not be column headers
	   [filesread,::loadparams[`filename];
	    loadparams[`headers] xcol $[0h>type loadparams[`separator];{flip x!y}[loadparams[`headers]];::]@(loadparams[`types];loadparams[`separator])0:rawdata];
        // if it hasn't been read then we have to just read it as a list of lists
  	flip loadparams[`headers]!(loadparams[`types];first loadparams[`separator])0:rawdata];
 
 .lg.o[`dataloader;"Read ",(string count data)," rows"];

 // do some optional extra processing
 .lg.o[`dataloader;"processing data"];
 data:0!loadparams[`dataprocessfunc] . (loadparams;data);

 // enumerate the table - best to do this once
 .lg.o[`dataloader;"Enumerating"];
 data:$[`symdir in key loadparams;
  .Q.en[loadparams[`symdir];data];
  .Q.en[loadparams[`dbdir];data]]; 

 writedatapartition[loadparams[`dbdir];;loadparams[`partitiontype];loadparams[`partitioncol];loadparams[`tablename];data] each distinct loadparams[`partitiontype]$data[loadparams`partitioncol];
 
 // garbage collection
 if[loadparams`gc; .gc.run[]];
 } 

writedatapartition:{[dbdir;partition;partitiontype;partitioncol;tablename;data]
 // sub-select the data to write
 towrite:data where partition=partitiontype$data partitioncol;
 
 // generate the write path
 writepath:` sv .Q.par[dbdir;partition;tablename],`;
 .lg.o[`dataloader;"writing ",(string count towrite)," rows to ",string writepath];
 
 // splay the table - use an error trap
 .[upsert;(writepath;towrite);{.lg.e[`dataloader;"failed to save table: ",x]}];
 
 // make sure the written path is in the partition dictionary
 partitions[writepath]:(tablename;partition);
 }

finish:{[loadparams]
 
 if[count loadparams`compression;
	.lg.o[`dataloader;"setting compression parameters to "," " sv string loadparams`compression];
	.z.zd:loadparams`compression];
 // re-sort and set attributes on each partition
 {.sort.sorttab(x;where partitions[;0]=x)} each distinct value partitions[;0];
  
 // unset .z.zd
 @[system;"x .z.zd";()];
 
 // garbage collection
 if[loadparams`gc; .gc.run[]];
 }

// load all the files from a specified directory
loadallfiles:{[loadparams;dir]
 
 // reset the partitions and files read variables 
 partitions::()!();
 filesread::(); 
 
 // Check the input
 if[not 99h=type loadparams; .lg.e[`dataloader; ".loader.loadallfiles requires a dictionary parameter"]];
 
 // required fields
 req:`headers`types`tablename`dbdir`separator;
 if[not all req in key loadparams;
     .lg.e[`dataloader;"loaddata requires a dictionary parameter with keys of ",(", " sv string req)," : missing ",", " sv string req except key loadparams]];

 // join the loadparams with some default values
 loadparams:(`dataprocessfunc`chunksize`partitioncol`partitiontype`compression`gc!({[x;y] y};`int$100*2 xexp 20;`time;`date;();0b)),loadparams;

 // required types
 reqtypes:`headers`types`tablename`dbdir`symdir`chunksize`partitioncol`partitiontype`gc!`short$(11;10;-11;-11;-11;-6;-11;-11;-1);
 
 // check the types
 if[count w:where not (type each loadparams key reqtypes)=reqtypes;
     .lg.e[`dataloader;"incorrect types supplied for ",(", " sv string w)," parameter(s). Required type(s) are ",", " sv string reqtypes w]];
 if[not 10h=abs type loadparams`separator; .lg.e[`dataloader;"separator must be a character or enlisted character"]];
 if[not 99h<type loadparams`dataprocessfunc; .lg.e[`dataloader;"dataprocessfunc must be a function"]];
 if[not loadparams[`partitiontype] in `date`month`year`int; .lg.e[`dataloader;"partitiontype must be one of `date`month`year`int"]];
 if[not count[loadparams`headers]=count loadparams[`types] except " "; .lg.e[`dataloader;"headers and non-null separators must be the same length"]]; 
 if[c:count loadparams[`compression]; if[not (3=c) and type[loadparams[`compression]] in 6 7h; .lg.e[`dataloader;"compression parameters must be a 3 item list of type int or long"]]];
 
 // if a filepattern was specified ensure that it's a list
 if[(`filepattern in key loadparams) & 10h=type loadparams[`filepattern];loadparams[`filepattern]:enlist loadparams[`filepattern]];

 // get the contents of the directory based on optional filepattern
 filelist:$[`filepattern in key loadparams;(key dir:hsym dir) where max like[key dir;] each loadparams[`filepattern];key dir:hsym dir];
 
 // create the full path
 filelist:` sv' dir,'filelist;
 
 // Load each file in chunks
 {[loadparams;file] 
  .lg.o[`dataloader;"**** LOADING ",(string file)," ****"];
  .Q.fsn[loaddata[loadparams,(enlist`filename)!enlist file];file;loadparams`chunksize]}[loadparams] each filelist;
 
 // finish the load
 finish[loadparams];
 }
