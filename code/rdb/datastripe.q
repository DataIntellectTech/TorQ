\d .rdb

datastripeendofperiod:{[currp;nextp;data]
    .lg.o[`reload;"reload command has been called remotely"];

    // remove periods of data from tables
    t:tables[`.] except ignorelist;

    lasttime:nextp-.ds.periodstokeep*(nextp-currp);
    tabs:{![x;enlist (<;y;z);0b;0#`]}'[t;`time;lasttime];
    .lg.o[`reload;"Kept ",string[.ds.periodstokeep]," period",$[.ds.periodstokeep>1;"s";""]," of data from : ",", " sv string[tabs]];

    // update the access table in the rdb
    .rdb.access:update start:lasttime from .rdb.access where tablename in t,start<lasttime;

    };

\d .

initdatastripe:{
        // update endofday and endofperiod functions
    endofday::.rdb.endofday;
    endofperiod::.rdb.datastripeendofperiod;
    .rdb.tablekeycols:.ds.loadtablekeycols[];
    .rdb.access:([table:key .rdb.tablekeycols] start:.ds.getstarttime each (key .rdb.tablekeycols) ; end:0Np ; keycol:value .rdb.tablekeycols ; segmentID:first .ds.segmentid);
    };

if[.ds.datastripe;.proc.addinitlist[(`initdatastripe;`)]];

