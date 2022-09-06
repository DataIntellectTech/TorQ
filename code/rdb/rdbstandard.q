// Get the relevant RDB attributes
.proc.getattributes:{`date`tables!(.rdb.rdbpartition[],();tables[])}

\d .rdb

/- Move a table from one namespace to another
/- this could be used in the end-of-day function to move the heartbeat and logmsg
/- tables out of the top level namespace before the save down, then move them 
/- back when done.
moveandclear:{[fromNS;toNS;tab] 
 if[tab in key fromNS;
  set[` sv (toNS;tab);0#fromNS tab];
  eval(!;enlist fromNS;();0b;enlist enlist tab)]}

/-drop date from rdbpartition
rmdtfromgetpar:{[date]
        rdbpartition:: rdbpartition except date;
        .lg.o[`rdbpartition;"rdbpartition contains - ","," sv string rdbpartition];
        }
