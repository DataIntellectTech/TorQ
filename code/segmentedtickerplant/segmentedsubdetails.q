segmentedsubdetails:{[tabs;instruments;id]
 `schemalist`logfilelist`rowcounts`date`logdir`filters!(.ps.subscribe\:[tabs;instruments];.stplg.replaylog[tabs];tabs#.stplg `rowcount;(.eodtime `d);`$getenv`KDBTPLOG;[select table,wcRef from tpconfig where segmentID=procmap[id]])
 }
