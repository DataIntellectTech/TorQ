// config settings
\d .replay
partandmerge:1b                         //setting to do a replay where the data is partitioned and then merged on disk
tempdir:hsym`$getenv[`KDBTESTS],"/merge/tplogreplay/tempmergedir";
exitwhencomplete:1b
autoreplay:1b
sortcsv:hsym`$getenv[`KDBTESTS],"/merge/tplogreplay/sort.csv"
//merge limits controlled by values set it config
