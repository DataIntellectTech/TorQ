// Sort Slave config

\d .wdb
savedir:hsym`$getenv[`TORQHOME],"/wdbhdb"                        // location to save wdb data
mode:`sort                              // the wdb process can operate in three modes
                                        // 1. saveandsort:      the process will subscribe for data,
                                        //                      periodically write data to disk and at EOD it will flush
                                        //                      remaining data to disk before sorting it and informing
                                        //                      GWs, RDBs and HDBs etc...
                                        // 2. save:             the process will subscribe for data,
                                        //                      periodically write data to disk and at EOD it will flush
                                        //                      remaining data to disk.  It will then inform it's respective
                                        //                      sort mode process to sort the data
                                        // 3. sort:             the process will wait to get a trigger from it's respective
                                        //                      save mode process.  When this is triggered it will sort the
                                        //                      data on disk, apply attributes and the trigger a reload on the
                                        //                      rdb and hdb processes

mergenumrows:100000                                             // default number of rows for merge process
mergenumtab:`quote`trade!10000 50000    // specify number of rows per table
hdbdir:`:hdb                            // move wdb database to different location
sortcsv:hsym first .proc.getconfigfile["sort.csv"]              // location of csv file
gc:1b                                   // garbage collect at appropriate points (after each table save and after sorting data)
tickerplanttypes:rdbtypes:hdbtypes:gatewaytypes:sorttypes:sortslavetypes:()     // sortslaves don't need these connections

// Server connection details
\d .servers
CONNECTIONS:()                          // sortslave doesn't need to connect to other processes
STARTUP:1b                                      // create connections

