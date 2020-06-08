/
Louise Belshaw
louise.belshaw@aquaq.co.uk
AquaQ Analytics (info@aquaq.co.uk)

USAGE OF COMPRESSION:

NOTE: Please use with caution.
To SHOW a table of files to be compressed and how before execution, use:

-with a specified csv driver file:
.cmp.showcomp[`:/path/to/hdb;`:/path/to/csv; maxagefilestocompress]

OR
-with compressionconfig.csv file located in the config folder (TORQ/src/config/compressionconfig.csv):
.cmp.showcomp[`:/path/to/hdb;.cmp.inputcsv; maxagefilestocompress]

To then COMPRESS all files:

.cmp.compressmaxage[`:/path/to/hdb;`:/path/to/csv; maxagefilestocompress]
OR
.cmp.compressmaxage[`:/path/to/hdb;.cmp.inputcsv; maxagefilestocompress]

If you don't care about the maximum age of the files and just want to COMPRESS up to the oldest files in the db then use:

.cmp.docompression[`:/path/to/hdb;`:/path/to/csv]
OR
.cmp.docompression[`:/path/to/hdb;.cmp.inputcsv]

csv should have the following format:

table,minage,column,calgo,cblocksize,clevel
default,10,default, 2, 17,6
quotes, 10,time, 2, 17, 5
quotes,10,src,2,17,4
depth, 10,default, 1, 17, 8

-tables in the db but not in the config tab are automatically compressed using default params
-tabs with cols specified will have other columns compressed with default (if default specified for cols of tab, all cols are comp in that tab)
-algo 0 decompresses the file, or if not compressed ignores
-config file could just be one row to compress everything older than age with the same params:

table,minage,column,calgo,cblocksize,clevel
default,10,default,2,17,6

The gzip algo (2) is not necessarily included on windows and unix systems.
See: code.kx.com/wiki/Cookbook/FileCompression for more details

For WINDOWS users:

The minimum block size for compression on windows is 16.

\

\d .cmp

inputcsv:@[value;`inputcsv;first .proc.getconfigfile["compressionconfig.csv"]];

if[-11h=type inputcsv;inputcsv:string inputcsv];

checkcsv:{[csvtab]
    // include snappy (3) for version 3.4 or after
    allowedalgos:0 1 2,$[.z.K>=3.4;3;()];
    if[0b~all colscheck:`table`minage`column`calgo`cblocksize`clevel in (cols csvtab);
         .lg.e[`compression;err:inputcsv," has incorrect column layout at column(s): ", (" " sv string where not colscheck), ". Should be `table`minage`column`calgo`cblocksize`clevel."];'err];
    if[count checkalgo:exec i from csvtab where not calgo in allowedalgos;
        .lg.e[`compression; err:inputcsv, ": incorrect compression algo in row(s): ",(", " sv string -1_allowedalgos)," or ",(string last allowedalgos),"."];'err];
    if[count checkblock:exec i from csvtab where calgo in 1 2, not cblocksize in 12 + til 9;
        .lg.e[`compression; err:inputcsv,": incorrect compression blocksize at row(s): ", (" " sv string checkblock), ". Should be between 12 and 19."];'err];
    if[count checklevel: exec i from csvtab where calgo in 2, not clevel in til 10;
        .lg.e[`compression;err:inputcsv,": incorrect compression level at row(s): ", (" " sv string checklevel), ". Should be between 0 and 9."];'err];
    if[.z.o like "w*"; if[count rowwin:where ((csvtab[`cblocksize] < 16) & csvtab[`calgo] > 0);
        .lg.e[`compression;err:inputcsv," :incorrect compression blocksize for windows at row: ", (" " sv string rowwin), ". Must be more than or equal to 16."];'err]];
    if[(any nulls: any null (csvtab[`column];csvtab[`table];csvtab[`minage];csvtab[`clevel]))>0;
        .lg.e[`compression;err:inputcsv," has empty cells in column(s): ", (" " sv string `column`table`minage`clevel where nulls)];'err];}

loadcsv:{[inputcsv]
    compressioncsv::@[{.lg.o[`compression;"Opening ", x];("SISIII"; enlist ",") 0:"S"$x}; (string inputcsv); {.lg.e[`compression;"failed to open ", (x)," : ",y];'y}[string inputcsv]];
    checkcsv[compressioncsv];}

traverse:{$[(0=count k)or x~k:key x; x; .z.s each ` sv' x,/:k where not any k like/:(".d";"*.q";"*.k";"*#")]}

hdbstructure:{
    t:([]fullpath:(raze/)traverse x); // orig traverse
     // calculate the length of the input path
    base:count "/" vs string x;
     // split out the full path
    t:update splitcount:count each split from update split:"/" vs' string fullpath,column:`,table:`,partition:(count t)#enlist"" from t;
     // partitioned tables
    t:update partition:split[;base],table:`$split[;base+1],column:`$split[;base+2] from t where splitcount=base+3;
     // splayed
    t:update table:`$split[;base],column:`$split[;base+1] from t where splitcount=base+2;
     // cast the partition type
    t:update partition:{$[not all null r:"D"$'x;r;not all null r:"M"$'x;r;"I"$'x]}[partition] from t;
     /- work out the age of each partition
     $[14h=type t`partition; t:update age:.z.D - partition from t;
           13h=type t`partition; t:update age:(`month$.z.D) - partition from t;
           // otherwise it is ints.  If all the values are within 1000 and 3000
           // then assume it is years
           t:update age:{$[all x within 1000 3000; x - `year$.z.D;(count x)#0Ni]}[partition] from t];
    delete splitcount,split from t}

showcomp:{[hdbpath;csvpath;maxage]
    /-load csv
    loadcsv[$[10h = type csvpath;hsym `$csvpath;hsym csvpath]];
    .lg.o[`compression;"scanning hdb directory structure"];
    /-build paths table and fill age
    $[count key (` sv hdbpath,`$"par.txt");
	pathstab:update 0W^age from (,/) hdbstructure'[hsym each `$(read0 ` sv hdbpath,`$"par.txt")];
	pathstab:update 0W^age from hdbstructure[hsym hdbpath]];
    /-delete anything which isn't a table
    pathstab:delete from pathstab where table in `;
    /-tables that are in the hdb but not specified in the csv - compress with `default params
    comptab:2!delete minage from update compressage:minage from compressioncsv;
    /-specified columns and tables
    a:select from comptab where not table=`default, not column=`default;
    /-default columns, specified tables
    b:select from comptab where not table=`default,column=`default;
    /-defaults
    c:select from comptab where table = `default, column =`default;
    /-join on defaults to entire table
    t: pathstab,'(count pathstab)#value c;
    /- join on for specified tables
    t: t lj 1!delete column from b;
    /- join on table and column specified information
    t: t lj a;
    /- in case of no default specified, delete from the table where no data is joined on
    t: delete from t where calgo=0Nj,cblocksize=0Nj,clevel=0Nj;
    .lg.o[`compression;"getting current size of each file up to a maximum age of ",string maxage];
    update currentsize:hcount each fullpath from select from t where age within (compressage;maxage) }

compressfromtable:{[table]
    statstab::([] file:`$(); algo:`int$(); compressedLength:`long$();uncompressedLength:`long$());
    {compress[x `fullpath;x `calgo;x `cblocksize;x `clevel; x `currentsize]} each table;}

/- call the compression with a max age paramter implemented
compressmaxage:{[hdbpath;csvpath;maxage]
    compressfromtable[showcomp[hdbpath;csvpath;maxage]];
    summarystats[];
    }

docompression:compressmaxage[;;0W];

summarystats:{
    /- table with compressionratio for each file
    statstab::`compressionratio xdesc (update compressionratio:?[algo=0; neg uncompressedLength%compressedLength; uncompressedLength%compressedLength] from statstab);
    compressedfiles: select from statstab where not algo = 0;
    uncompressedfiles:select from statstab where algo = 0;
    /- summarytable
    memorysavings: ((sum compressedfiles`uncompressedLength) - sum compressedfiles`compressedLength) % 2 xexp 20;
    totalcompratio: (sum compressedfiles`uncompressedLength) % sum compressedfiles`compressedLength;
    memoryusage:((sum uncompressedfiles`uncompressedLength) - sum uncompressedfiles`compressedLength) % 2 xexp 20;
    totaldecompratio: neg (sum uncompressedfiles`compressedLength) % sum uncompressedfiles`uncompressedLength;
    .lg.o[`compression;"Memory savings from compression: ", .Q.f[2;memorysavings], "MB. Total compression ratio: ", .Q.f[2;totalcompratio],"."];
    .lg.o[`compression;"Additional memory used from de-compression: ",.Q.f[2;memoryusage], "MB. Total de-compression ratio: ", .Q.f[2;totaldecompratio],"."];
    .lg.o[`compression;"Check .cmp.statstab for info on each file."];}

compress:{[filetoCompress;algo;blocksize;level;sizeuncomp]
    compressedFile: hsym `$(string filetoCompress),"_kdbtempzip";
    / compress or decompress as appropriate:
    cmp:$[algo=0;"de";""];
    $[((0 = count -21!filetoCompress) & not 0 = algo)|((not 0 = count -21!filetoCompress) & 0 = algo);
        [.lg.o[`compression;cmp,"compressing ","file ", (string filetoCompress), " with algo: ", (string algo), ", blocksize: ", (string blocksize), ", and level: ", (string level), "."];
         / perform the compression/decompression
        if[0=algo;comprL:(-21!filetoCompress)`compressedLength];
        -19!(filetoCompress;compressedFile;blocksize;algo;level);
         / check the compressed/decomp file and move if appropriate; else delete compressed file and log error
        $[((get compressedFile)~sf:get filetoCompress) & (count -21!compressedFile) or algo=0;
            [.lg.o[`compression;"File ",cmp,"compressed ","successfully; matches orginal. Deleting original."];
                system "r ", (last ":" vs string compressedFile)," ", last ":" vs string filetoCompress;
                / move the hash files too.
                hashfilecheck[compressedFile;filetoCompress;sf];
                /-log to the table if the algo wasn't 0
                statstab,:$[not 0=algo;(filetoCompress;algo;(-21!filetoCompress)`compressedLength;sizeuncomp);(filetoCompress;algo;comprL;sizeuncomp)]];
            [$[not count -21!compressedFile;
		[.lg.o[`compression; "Failed to compress file ",string[filetoCompress]];hdel compressedFile];
		[.lg.o[`compression;cmp,"compressed ","file ",string[compressedFile]," doesn't match original. Deleting new file"];hdel compressedFile]]]]
        ];
        / if already compressed/decompressed, then log that and skip.
        .lg.o[`compression; "file ", (string filetoCompress), " is already ",cmp,"compressed",". Skipping this file"]]}

hashfilecheck:{[compressedFile;filetoCompress;sf]
    / if running 3.6 or higher, account for anymap type for nested lists
    / check for double hash file if nested data contains symbol vector/atom
    $[3.6<=.z.K;
        if[77 = type sf; system "r ", (last ":" vs string compressedFile),"# ", (last ":" vs string filetoCompress),"#";
            .[{system "r ", (last ":" vs string x),"## ", (last ":" vs string y),"##"};(compressedFile;filetoCompress);.lg.o[`compression;"File does not have enumeration domain"]]];
        / if running below 3.6, nested list types will be 77h+t and will not have double hash file    
        if[78 <= type sf; system "r ", (last ":" vs string compressedFile),"# ", (last ":" vs string filetoCompress),"#"]]}