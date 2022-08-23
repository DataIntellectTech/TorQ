\d .merge

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
