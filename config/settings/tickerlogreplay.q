// default configuration for the tickerplant replay

\d .replay

// Variables
firstmessage:0                          // the first message to execute
lastmessage:0W                          // the last message to replay
messagechunks:0W                        // the number of messages to replay at once
schemafile:`                            // the schema file to load data in to
tablelist:enlist `all                   // the tables to replay into (to allow subsets of tp logs to be replayed).  `all means all
hdbdir:`                                // the hdb directory to write to
tplogfile:`                             // the tp log file to replay.  Only this or tplogdir should be used (not both)
tplogdir:`                              // the tp log directory to read the log files from.  Only this or tplogfile should be used (not both)
partitiontype:`date                     // the partitioning of the database.  Can be date, month or year (int would have to be handled bespokely)
emptytables:1b                          // whether to overwrite any tables at start up
sortafterreplay:1b                      // whether to re-sort the data at the end of the replay.  Sort order is determined by the result of sortandpart[`tablename]
partafterreplay:1b                      // whether to apply the parted attribute after the replay.  Parted column is determined by result of first sortandpart[`tablename]
basicmode:0b                            // do a basic replay, which replays everything in, then saves it down with .Q.hdpf[`::;d;p;`sym]
exitwhencomplete:1b                     // exit when the replay is complete
checklogfiles:0b                        // check if the log file is corrupt, if it is then write a new "good" file and replay it instead
gc:1b                                   // garbage collect at appropriate points (after each table save and after the full log replay)
autoreplay:1b                           // start replaying logs at the end of the script without any further user input
clean:1b				// clean existing folders on start up. Needed if a replay screws up and we are replaying by chunk or multiple tp logs
upd:{[t;x] insert[t;x]}                 // default upd function used for replaying data

sortcsv:`:config/sort.csv               //location of  sort csv file

compression:()                          //specify the compress level, empty list if no required
partandmerge:0b                         //setting to do a replay where the data is partitioned and then merged on disk
tempdir:`:tempmergedir                  //location to save data for partandmerge replay
mergenumrows:10000000;                  //default number of rows for merge process
mergenumtab:`quote`trade!10000 50000;   //specify number of rows per table for merge process

/ - settings for the common save code (see code/common/save.q)
.save.savedownmanipulation:()!()        // a dict of table!function used to manipuate tables at EOD save
.save.postreplay:{{[d;p] }}             // post replay function, invoked after all the tables have been written down for a given log file

// turn off some of the standard stuff
\d .proc
loadhandlers:0b
logroll:0b
