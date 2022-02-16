// stripe data across rdbs

.rdb.datastripe:1b;

.rdb.datastripeendofperiod:{[currp;nextp;data]
    .lg.o[`reload;"reload command has been called remotely"];
    
    // remove periods of data from tables
    t:tables[`.] except .rdb.ignorelist;
    lasttime:currp-.rdb.periodstokeep*(nextp-currp);
    tabs:{![x;enlist (<;y;z);0b;0#`]}'[t;`time;lasttime];
    .lg.o[`reload;"Kept ",string[.rdb.periodstokeep]," period",$[.rdb.periodstokeep>1;"s";""]," of data from : ",", " sv string[tabs]];
    };


initdatastripe:{
	// update endofday and endofperiod functions
    endofday::endofday;
    endofperiod::.rdb.datastripeendofperiod;
    };

if[.rdb.datastripe;initdatastripe[]];