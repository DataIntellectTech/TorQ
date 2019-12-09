// DATADOG CHECKS

//Create torqdog namespace
\d .dg

//Functions are set to return 1b or 0b based on the health of the service.
//A simple return is a simple ping.
//These checks run every time crontab is run.
.dg.is_ok:{[x]
        f:$[@[{[x].proc.proctype in key .dg.handlers};`;0b];
                .dg.handlers[.proc.proctype];
                .dg.default_is_ok];
        @[f;`;0b]
        }

.dg.default_is_ok:{[x]1b}

.dg.handlers:(`symbol$())!()

//Function to check if writedown is happening in the WDB
.dg.wdbstate:(0Np;0Nj)
.dg.is_wdb_ok:{[x] if[(`time$.z.p)<00:05:00.00;.dg.wdbstate:(0Np;0); :1b];
        s:$[.[.wdb.tabsizes;`trade`rowcount]>.dg.wdbstate[1];1b;0b];
       .dg.wdbstate:(.z.p;.[.wdb.tabsizes;`trade`rowcount]);:s};
.dg.handlers[`wdb]:.dg.is_wdb_ok

//Function to check if date is correct in the RDB
.dg.quotedate:{$[1=count exec distinct "d"$time from tables[]2;.z.d=first exec distinct "d"$time from tables[]2;1b;0b]};
.dg.tradedate:{$[1=count exec distinct "d"$time from tables[]4;.z.d=first exec distinct "d"$time from tables[]4;1b;0b]};
.dg.is_rdb_ok:{min .dg.quotedate[],.dg.tradedate[]};
.dg.handlers[`rdb]:.dg.is_rdb_ok

//Function to get the previous days date to do hdb_checks  - min value - if any 0bs returns 0b - something is wrong.
.dg.is_hdb_ok:{
        prevdate:$[(`time$.z.p)>00:05:00.000;.z.d-1;.z.d-2];
        min value .dg.hdb_checks[prevdate]
        }
//Creates checks dictionary 
.dg.hdb_checks:{[x]
        checks:()!();
        checks[`reload]:x in `. `date;                                                                             /Check reload is working (date is in process)
          if[not checks[`reload];.lg.e[`hdbchecks;"Reload is not working in HDB (run reload[] in hdb process)"]];  /Error log is check fails on reload
        checks[`folder]:(`$string x) in key `:.;                                                                   /Check folder for data is in partition
          if[not checks[`folder];.lg.e[`hdbchecks;"Yesterday's date was not saved to disk"]];                      /Error log if check fails on saved folder
        tablecount:{[date;table] 0<count get[`$":",string date]table}x;                                            /Check there is data in table
        checks[`quote]:tablecount `quote;                                                                          /Check data in quote
           if[not checks[`quote];.lg.e[`hdbchecks;"No data in quote table"]];                                      /Error log if check fails on data in quotes
        checks[`trade]:tablecount `trade;                                                                          /Check data in trade
            if[not checks[`trade];.lg.e[`hdbchecks;"No data in trade table"]];                                     /Error log if checks fails on data in trades
        checks                                                                                                     /Returns checks dictionary
        }
.dg.handlers[`hdb]:.dg.is_hdb_ok

//Function to check if TP is updating. 
//This keeps the state and checks that it is getting updates
//The last time it was check and .u.i (log file message count) are stored for comparison
//Sets the tpstate to null timestamp and null long.
.dg.tpstate:(0Np;0Nj)
.dg.is_tickerplant_ok:{[x]
        if[(`time$.z.p)<00:05:00.00;.dg.tpstate:(0Np;0); :1b];
        s:$[.u.i>.dg.tpstate[1];1b;0b];
        .dg.tpstate:(.z.p;.u.i);:s};
.dg.handlers[`tickerplant]:.dg.is_tickerplant_ok

