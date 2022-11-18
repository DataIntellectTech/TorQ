// Get the relevant tailreader attributes
.proc.getattributes:{default:`date`tables`procname!(.z.d;tables[];.proc.procname);
    / get all cols that contains date (of type "pdz")
    timecolumns:1!{tcols:exec c from meta value x where t in"pdz";
        (enlist[`tablename]!enlist x),
            /functional select to get the min value (defaults to `timestamp$.z.d for starttimestamp)
            enlist[`timecolumns]!enlist?[x;();();
                tcols!(enlist,/:enlist each($;enlist`timestamp),/:enlist each((?),/:enlist each(=;0W),/:mtcols),'`.z.d,'mtcols:enlist each min,/:tcols),\:0Wp]}each tables[`.];
    / update date attribute for .gw.partdict and .gw.attributesrouting
    default[`date]:asc default[`date]union first[d]+til 1+last deltas d:exec(min;max)@\:distinct`date$raze[value each timecolumns][;0]from timecolumns;
        / get segmentfilter from segmenting.csv and filtermap.csv
        // assuming they are striped by sym and using a striping function
    segmenting:("SIS";enlist",")0:hsym`$getenv[`KDBCONFIG],"/segmenting.csv";
    segment:select wcRef,table from segmenting where segmentID in "I"$string .ds.segmentid;
    filtermap:1!("S*";enlist",")0:hsym`$getenv[`KDBCONFIG],"/filtermap.csv";
    instrumentsfilter:1!select tablename:table,instrumentsfilter:{ssr[x;"sym";""]}each filter from segment ij filtermap;
    inftc:instrumentsfilter uj timecolumns;        
    dataaccess:enlist[`dataaccess]!enlist`segid`tablename!(.ds.segmentid 0;(exec tablename from inftc)!value inftc);
    default,:dataaccess;
    default}

/temporary drop functions to remove int columns from trade/quote tables - solving type error during .proc.getattributes function
\d .tr
dropinttrade:{
    trade::?[`trade;();0b;`time`sym`price`size`stop`cond`ex`side!`time`sym`price`size`stop`cond`ex`side];
    :trade;
  }

dropintquote:{
    quote::?[`quote;();0b;`time`sym`bid`ask`bsize`asize`mode`ex`src!`time`sym`bid`ask`bsize`asize`mode`ex`src];
    :quote;
  }