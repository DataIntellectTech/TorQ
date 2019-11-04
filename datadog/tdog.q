// DATADOG CHECKS

//Create torqdog namespace
\d .dg

//functions are set to return 1b or 0b based on the health of the service
//A simple return is a simple ping. Logic can be added by making a custom handler based on proctype and potenitally provtype.

.dg.is_ok:{[x]
        f:$[@[{[x].proc.proctype in key .dg.handlers};`;0b];
                .dg.handlers[.proc.proctype];
                .dg.default_is_ok];
        @[f;`;0b]
        }

.dg.default_is_ok:{[x]1b}

handlers:(`symbol$())!()

//Function to check if there is data in the WDB
.dg.wdbstate:(0Np;0Nj)
.dg.is_wdb_ok:{[x] if[(`time$.z.p)<00:05:00.00;.dg.wdbstate:(0Np;0); :1b];
        s:$[.[.wdb.tabsizes;`trade`rowcount]>.dg.wdbstate[1];1b;0b];
        .dg.wdbstate:(.z.p;.[.wdb.tabsizes;`trade`rowcount]);:s};
.dg.handlers[`wdb]:.dg.is_wdb_ok

//Function to check if there is data in the RDB
//.dg.rdbstate:(0Np;0Nj)
//.dg.is_rdb_ok:{[x] if[(`time$.z.p)<00:05:00.00;.dg.rdbstate:(0Np;0); :1b];
//        s:$[.[.rdb.tabsizes;`trade`rowcount]>.dg.rdbstate[1];1b;0b];
//        .dg.rdbstate:(.z.p;.[.rdb.tabsizes;`trade`rowcount]);:s};
//.dg.handlers[`rdb]:.dg.is_wdb_ok


//Function to check if all tables written down to hdb
.dg.is_hdb_ok:{[x]
        today:$[(`time$.z.P)>08:00:00.000;.z.d-1;.z.d-2];
        min value .dg.hdb_checks[today]
        }
.dg.hdb_checks:{[x]
        checks:()!();
        checks[`reload]:x in `. `date;
        checks[`folder]:(`$string x) in key `:.;
        tablecount:{[date;table] 0<count get[`$":",string date]table}x;
        checks[`quote]:tablecount `quote;
        checks[`trade]:tablecount `trade;
        checks
        }
.dg.handlers[`hdb]:.dg.is_hdb_ok

//Function to check if TP is updating. 
//This keeps the state and checks that it is getting updates as well as having a handle from a given user
//The last time it was check and .u.i (log file message count) are stored for comparison
//Sets the tpstate to null timestamp and null long.
.dg.tpstate:(0Np;0Nj)
.dg.is_tickerplant_ok:{[x] if[(`time$.z.p)<00:05:00.00;.dg.tpstate:(0Np;0); :1b];
        s:$[.u.i>.dg.tpstate[1];1b;0b];
        .dg.tpstate:(.z.p;.u.i);:s};
.dg.handlers[`tickerplant]:.dg.is_tickerplant_ok
