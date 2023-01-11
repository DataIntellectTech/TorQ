// Get the relevant RDB attributes
.proc.getattributes:{default:`date`tables`procname!(.rdb.rdbpartition[];tables[] except .rdb.ignorelist;.proc.procname);
    / get all cols that contains date (of type "pdz")
    timecolumns:1!{tcols:exec c from meta value x where t in"pdz";
        (enlist[`tablename]!enlist x),
            /functional select to get the min value (defaults to `timestamp$.z.d for starttimestamp)
            enlist[`timecolumns]!enlist?[x;();();
                tcols!(enlist,/:enlist each($;enlist`timestamp),/:enlist each((?),/:enlist each(=;0W),/:mtcols),'`.z.d,'mtcols:enlist each min,/:tcols),\:0Wp]}each tables[`.] except .rdb.ignorelist;
    / update date attribute for .gw.partdict and .gw.attributesrouting
    default[`date]:asc default[`date]union first[d]+til 1+last deltas d:exec(min;max)@\:distinct`date$raze[value each timecolumns][;0]from timecolumns;
    if[.ds.datastripe;
        / for striped rdbs, retrieve stripe mapping from stp and deduce instruments in each table to report as attributes to the gateway 
        stphandle:first exec w from .servers.getservers[`proctype;`segmentedtickerplant;()!();1b;0b];
        .ds.tblstripe:stphandle"select tbl,filts from .stpps.subrequestfiltered where handle = .z.w";   /to be changed to avoid blocking handle
        tblstripemapping:update stripenum:{last .ds.tblstripe[`filts][x;0;0]}each til count .ds.tblstripe from .ds.tblstripe;
        instrumentsfilter:1!select tablename:tbl,instrumentsfilter:stripenum from tblstripemapping;
        inftc:instrumentsfilter uj timecolumns;
        dataaccess:enlist[`dataaccess]!enlist`segid`tablename!(.ds.segmentid 0;(exec tablename from inftc)!value inftc);
        default,:dataaccess;
        ];
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
