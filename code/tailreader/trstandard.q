// Get the relevant tailreader attributes
.proc.getattributes:{default:`date`tables`procname!(.z.d;tables[] except .wdb.ignorelist;.proc.procname);
    / get all cols that contains date (of type "pdz")
    timecolumns:1!{tcols:exec c from meta value x where t in"pdz";
        (enlist[`tablename]!enlist x),
            /functional select to get the min value (defaults to `timestamp$.z.d for starttimestamp)
            enlist[`timecolumns]!enlist?[x;();0b;                  //For 3rd arg: () produces dictionary with value of type list, first value of type 12h (desired) but does NOT work for tailreader. 0b runs without error but no dict created and type list on first value when flipped
                tcols!(enlist,/:enlist each($;enlist`timestamp),/:enlist each((?),/:enlist each(=;0W),/:mtcols),'`.z.d,'mtcols:enlist each min,/:tcols),\:0Wp]}each tables[`.] except .wdb.ignorelist;
    timecolumns:update timecolumns:(flip each timecolumns) from timecolumns;
    timecolumns:update timecolumns:{(y)[x]:(raze y);y}'[key each timecolumns;timecolumns] from timecolumns;
    / update date attribute for .gw.partdict and .gw.attributesrouting
    default[`date]:asc default[`date]union first[d]+til 1+last deltas d:exec(min;max)@\:distinct`date$raze[value each timecolumns][;0]from timecolumns;
    / retrieve striped instruments for tr tables
    instrumentsfilter:1!select tablename:tbl,instrumentsfilter:stripenum from .ds.tblstripemapping;
    inftc:instrumentsfilter uj timecolumns;
    dataaccess:enlist[`dataaccess]!enlist`segid`tablename!(.ds.segmentid 0;(exec tablename from inftc)!value inftc);
    default,:dataaccess;
    default}