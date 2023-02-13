// Get the relevant RDB attributes
.proc.getattributes:{default:`date`tables`procname!(.rdb.rdbpartition[];tables[] except .rdb.ignorelist;.proc.procname);
    / get all cols that contains date (of type "pdz")
    timecolumns:1!{tcols:exec c from meta x where t in"pdz";
        (enlist[`tablename]!enlist x),
            /functional select to get the min value (defaults to `timestamp$.z.d for starttimestamp)
            enlist[`timecolumns]!enlist?[x;();();
                tcols!(enlist,/:enlist each($;enlist`timestamp),/:enlist each((?),/:enlist each(=;0W),/:mtcols),'`.z.d,'mtcols:enlist each min,/:tcols),\:0Wp]}each tables[`.] except .rdb.ignorelist;
    / update date attribute for .gw.partdict and .gw.attributesrouting
    default[`date]:asc default[`date]union first[d]+til 1+(-) . d:exec(max;min)@\:distinct`date$raze[value each timecolumns][;0]from timecolumns;
    instrumentsfilter:1!select tablename:tbl,instrumentsfilter:stripenum from .ds.tblstripemapping;
    inftc:instrumentsfilter uj timecolumns;
    dataaccess:enlist[`dataaccess]!enlist`segid`tablename!(.ds.segmentid 0;(exec tablename from inftc)!value inftc);
    default,:dataaccess;
    default}

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
