.servers.CONNECTIONS:`discovery`hdb;
.servers.USERPASS:`admin:admin;
\d .replay
partandmerge:1b                         //setting to do a replay where the data is partitioned and then merged on disk
tempdir:hsym`$getenv[`KDBTESTS],"/merge/tplogreplay/tempmergedir";               
mergenumrows:10000000;                  //default number of rows for merge process
mergenumtab:`quote`trade!10000 50000;   //specify number of rows per table for merge process
mergenumbytes:500000000                 // default partition bytesize for merge limit in merge process (only used when .merge.mergebybytelimit=1b)
exitwhencomplete:0b
autoreplay:0b
sortcsv:hsym`$getenv[`KDBTESTS],"/merge/tplogreplay/sort.csv"
