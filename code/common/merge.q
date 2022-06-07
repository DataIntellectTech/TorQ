\d .merge

partsizes:([ptdir:`symbol$()] rowcount:`long$(); bytes:`long$());

/- function to get additional partition(s) defined by parted attribute in sort.csv
getextrapartitiontype:{[tablename]
        /- check that that each table is defined or the default attributes are defined in sort.csv
        /- exits with error if a table cannot find parted attributes in tablename or default
        /- only checks tables that have sort enabled
        tabparts:$[count tabparts:distinct exec column from .sort.params where tabname=tablename,sort=1,att=`p;
                        [.lg.o[`getextraparttype;"parted attribute p found in sort.csv for ",(string tablename)," table"];
                        tabparts];
                        count defaultparts:distinct exec column from .sort.params where tabname=`default,sort=1,att=`p;
                        [.lg.o[`getextraparttype;"parted attribute p not found in sort.csv for ",(string tablename)," table, using default instead"];
                        defaultparts];
                        [.lg.e[`getextraparttype;"parted attribute p not found in sort.csv for ", (string tablename)," table and default not defined"]]
                ];
        tabparts
        };

/- function to check each partiton type specified in sort.csv is actually present in specified table
checkpartitiontype:{[tablename;extrapartitiontype]
        $[count colsnotintab:extrapartitiontype where not extrapartitiontype in cols get tablename;
                .lg.e[`checkpart;"parted columns ",(", " sv string colsnotintab)," are defined in sort.csv but not present in ",(string tablename)," table"];
                .lg.o[`checkpart;"all parted columns defined in sort.csv are present in ",(string tablename)," table"]];
	};



/- function to get list of distinct combiniations for partition directories
/- functional select equivalent to: select distinct [ extrapartitiontype ] from [ tablenme ]
getextrapartitions:{[tablename;extrapartitiontype]
        value each ?[tablename;();1b;extrapartitiontype!extrapartitiontype]
        };

/-function to return chunks that will be called in batch by mergebypart function
getpartchunks:{[partdirs;mergelimit]
  /-get table for function which only contains data for relevant partitions
  t:select from .merge.partsizes where ptdir in partdirs;
  r:$[.merge.mergebybytelimit;exec bytes from t;exec rowcount from t];
  (where r={$[z<x+y;y;x+y]}\[0;r;mergelimit]) cut exec ptdir from t
  };

mergebypart:{[tablename;dest;partchunks]
   .lg.o[`merge;"reading partition/partitions ", (", " sv string[partchunks])];
   chunks:get each partchunks;
   /-if multiple chunks have been read in chunks will be a list of tabs, if this is the case - join into single tab
   if[98<>type chunks;chunks:(,/)chunks];
   .lg.o[`resort;"Checking that the contents of this subpartition conform"];
   pattrtest:@[{@[x;y;`p#];0b}[chunks;];.merge.getextrapartitiontype[tablename];{1b}];
   if[pattrtest;
     /-p attribute could not be applied, data must be re-sorted by subpartition col (sym):
     .lg.o[`resort;"Re-sorting contents of subpartition"];
     chunks: xasc[.merge.getextrapartitiontype[tablename];chunks];
     .lg.o[`resort;"The p attribute can now be applied"];
     ];
   .lg.o[`merge;"upserting ",(string count chunks)," rows to ",string dest];
   /-merge columns and return boolean based on success of merge
   .[upsert;(dest;chunks);                     
     {.lg.e[`merge;"failed to merge to ", sting[dest], " from segments ", (", " sv string chunks)];}];
   };

/-read in data from partition column by column rather than read in entie partition and move to hdb
mergebycol:{[tableinfo;dest;segment]
  .lg.o[`merge;"upserting columns from ", (string[segment]), " to ", string[dest]];
  /- function to save column by column data from segments to hdb and return 1b for successful merge 0b for failed merge
  {[dest;segment;col]
    /-filepath to hdb partition column where data will be saved to
    destcol:(` sv dest, col);
    /-data from column in temp storage to be saved in hdb
    destdata: get segcol:` sv segment, col;
    .lg.o[`merge;"merging ", string[segcol], " to ", string[destcol]];
    /-upsert data to hdb column
    .[upsert;(destcol;destdata);
      {[destcol;e].lg.e[`merge;"failed to save data to ", string[destcol], " with error : ",e];}]
  }[dest;segment;] each cols tableinfo[1];
  };

/-hybrid method of the two functions above, calls the mergebycol function for partitions over a bytesize limit (kept track in .merge.partsizes) and mergebypart for remaining functions
mergehybrid:{[tableinfo;dest;partdirs;mergelimit]
  /-exec partition directories for this table from the tracking table partsizes, where the number of bytes is over the limit  
   overlimit:$[.merge.mergebybytelimit;
              exec ptdir from .merge.partsizes where ptdir in partdirs,bytes > mergelimit;
              exec ptdir from .merge.partsizes where ptdir in partdirs,rowcount > mergelimit
             ];
  if[(count overlimit)<>count partdirs;
    partdirs:partdirs except overlimit;
    .lg.o[`merge;"merging ",  (", " sv string partdirs), " by whole partition"];
    /-get partition chunks to merge in batch
    partchunks:getpartchunks[partdirs;mergelimit];
    mergebypart[tableinfo[0];(` sv dest,`)]'[partchunks];
    ];
  /-if columns are over the byte limit merge column by column
  if[0<>count overlimit;
    .lg.o[`merge;"merging ",  (", " sv string overlimit), " column by column"];
    mergebycol[tableinfo;dest]'[overlimit];
    /-if all partitions are over limit no .d file will have been created - check for .d file and if none exists create one
    if[()~key (` sv dest,`.d);
      .lg.o[`merge;"creating file ", (string ` sv dest,`.d)];
      (` sv dest,`.d) set cols tableinfo[1];
      ];
    ];
  };     
