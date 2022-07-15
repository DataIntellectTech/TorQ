// stripe data across rdbs

\d .ds


// Casting segid to symbol to enable free naming of segments
// segmentid variable defined by applying key to dictionary of input values
  
segmentid: `$.proc.params[`segid]

deletetablebefore:{![x;enlist (<;y;z);0b;0#`]}

\d .

.rdb.datastripeendofperiod:{[currp;nextp;data]
    .lg.o[`reload;"reload command has been called remotely"];
    
    // remove periods of data from tables
    t:tables[`.] except .rdb.ignorelist;
    lasttime:currp-.ds.periodstokeep*(nextp-currp);
    tabs:{![x;enlist (<;y;z);0b;0#`]}'[t;`time;lasttime];
    .lg.o[`reload;"Kept ",string[.ds.periodstokeep]," period",$[.ds.periodstokeep>1;"s";""]," of data from : ",", " sv string[tabs]];
    };


initdatastripe:{
	// update endofday and endofperiod functions
    endofday::.rdb.endofday;
    endofperiod::.rdb.datastripeendofperiod;
    };

if[.ds.datastripe;.proc.addinitlist[(`initdatastripe;`)]];
