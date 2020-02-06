// Bespoke WDB config
\d .wdb
ignorelist:`heartbeat`logmsg                                                                // list of tables to ignore
hdbtypes:`hdb                                                                               // list of hdb types to look for and call in hdb reload
rdbtypes:`rdb                                                                               // list of rdb types to look for and call in rdb reload
gatewaytypes:`gateway                                                                       // list of gateway types to inform at reload
tickerplanttypes:`tickerplant                                                               // list of tickerplant types to try and make a connection to
subtabs:`                                                                                   // list of tables to subscribe for (` for all)
subsyms:`                                                                                   // list of syms to subscribe for (` for all)
savedir:hsym`$getenv[`TORQHOME],"/wdbhdb"                                                   // location to save wdb data
numrows:100000                                                                              // default number of rows
numtab:`quote`trade!10000 50000                                                             // specify number of rows per table
mode:`save                                                                                  // the wdb process can operate in three modes	
                                                                                            // 1. saveandsort:     the process will subscribe for data,
                                                                                            //                     periodically write data to disk and at EOD it will flush
                                                                                            //                     remaining data to disk before sorting it and informing
                                                                                            //                     GWs, RDBs and HDBs etc...
                                                                                            // 2. save:            the process will subscribe for data,
                                                                                            //                     periodically write data to disk and at EOD it will flush
                                                                                            //                     remaining data to disk.  It will then inform it's respective
                                                                                            //                     sort mode process to sort the data
                                                                                            // 3. sort:            the process will wait to get a trigger from it's respective
                                                                                            //                     save mode process.  When this is triggered it will sort the
                                                                                            //                     data on disk, apply attributes and the trigger a reload on the
                                                                                            //                     rdb and hdb processes
writedownmode:`default                                                                      // the wdb process can periodically write data to disc and sort at EOD in two ways:
                                                                                            // 1. default          - the data is partitioned by [ partitontype ]
                                                                                            //                       at EOD the data will be sorted and given attributes according to sort.csv before being moved to hdb
                                                                                            // 2. partbyattr       - the data is partitioned by [ partitiontype ] and the column(s)assigned the parted attributed in sort.csv
                                                                                            //                       at EOD the data will be merged from each partiton before being moved to hdb
												
mergenumrows:100000                                                                         // default number of rows for merge process
mergenumtab:`quote`trade!10000 50000                                                        // specify number of rows per table

tpconnsleepintv:10                                                                          // number of seconds between attempts to connect to the tp
upd:insert                                                                                  // value of the upd function
replay:1b                                                                                   // replay the tickerplant log file
schema:1b                                                                                   // retrieve schema from tickerplant
settimer:0D00:00:10                                                                         // timer to check if data needs written to disk
partitiontype:`date                                                                         // set type of partition (defaults to `date, can be `date, `month or `year)
gmttime:1b                                                                                  // define whether the process is on gmttime or not
getpartition:{@[value;`.wdb.currentpartition;(`date^partitiontype)$(.z.D,.z.d)gmttime]}     // function to determine the partition value
reloadorder:`hdb`rdb                                                                        // order to reload hdbs and rdbs
hdbdir:`:hdb                                                                                // move wdb database to different location
sortcsv:hsym first .proc.getconfigfile"sort.csv"                                            // location of csv file
permitreload:1b                                                                             // enable reload of hdbs/rdbs
compression:()                                                                              // specify the compress level, empty list if no required
gc:1b                                                                                       // garbage collect at appropriate points (after each table save and after sorting data)
eodwaittime:0D00:00:10.000                                                                  // time to wait for async calls to complete at eod
tpcheckcycles:0W                                                                            // number of attempts to connect to tp before process is killed

// Server connection details
\d .servers
CONNECTIONS:`hdb`tickerplant`rdb`gateway`sort                                               // list of connections to make at start up
STARTUP:1b                                                                                  // create connections

