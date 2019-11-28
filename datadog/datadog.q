// DATADOG CHECKS

//Create torqdog namespace
\d .dg

//Functions are set to return 1b or 0b based on the health of the service.
//These checks run every time crontab is run.
.dg.is_ok:{
  f:$[@[{.proc.proctype in key .dg.handlers};`;0b];                                                                                /Process in handlers dictionary - index into handlers, else default.
    .dg.handlers[.proc.proctype];
    .dg.default_is_ok];   
  @[f;`;0b]                                                                                                                        /Error trap if .proc.proctype doesn't exist will send 0b
 }

.dg.default_is_ok:{1b}                                                                                                             /If check does not exist the process passes

handlers:(`symbol$())!()                                                                                                           /Creates empty handlers dictionary

//Function to check quote table writedown happened in the WDB
.dg.wdbstate:(0Np;0Nj)                                                                                                             /Initial wdbstate set to 0
.dg.is_wdb_ok:{[x] if[(`time$.z.p)<00:05:00.00;.dg.wdbstate:(0Np;0); :1b];                                                         /Clear wdb state at start of new day
 s:$[.[.wdb.tabsizes;(((exec from .wdb.tabsizes)[`tablename]);`rowcount)]>.dg.wdbstate[1];1b;0b];                           /Check rowcount in table is greater than last check
 .dg.wdbstate:(.z.p;.[.wdb.tabsizes;(((exec from .wdb.tabsizes)[`tablename]);`rowcount)]);:s};                                                                   /Set wdbstate to new rowcount and show value of s
.dg.handlers[`wdb]:.dg.is_wdb_ok                                                                                                   /Adds to handlers dictionary

//Function to check only one date and date is correct in the RDB
.dg.is_rdb_ok:{$[1=count .rdb.getpartition[];.z.d=first .rdb.getpartition[];1b;0b]};
.dg.handlers[`rdb]:.dg.is_rdb_ok                                                                                                   /Adds to handlers dictionary

//Function to check hdb is working correctly
.dg.is_hdb_ok:{
  prevdate:$[(`time$.z.p)>00:01:00.000;.z.d-1;.z.d-2];                                                                             /Get the date of the previous day
/    $[((prevdate-2000.01.01)mod 7) > 1;min value .dg.hdb_checks[prevdate];1]                                                      /Optional ignore HDB checks on Sun and Mon
  min value .dg.hdb_checks[prevdate]                                                                                               /Fails if any check fails
 }


//Creates checks dictionary 
.dg.hdb_checks:{[prevdate]
  checks:()!();                                                                                                                    /Sets checks dictionary to blank
  checks[`dateinprocess]:prevdate in `. `date;                                                                                     /Check data for prevdate is in process)
    if[not checks[`dateinprocess];.lg.e[`hdbchecks;"Yesterday's date data is not in the HDB process"]];                            /Error log if check fails here
  checks[`datesaved]:(`$string prevdate) in key `:.;                                                                               /Check folder for prevdate data is in partition
    if[not checks[`datesaved];.lg.e[`hdbchecks;"Yesterday's date was not saved to disk"]];                                         /Error log if check fails here
  tablecount:{[date;table] 0<count get[`$":",string date]table}prevdate;                                                           /Check there is data in table
  checks[`tabledata]:tablecount tables[][2];                                                                                       /Check data in table
    if[not checks[`tabledata];.lg.e[`hdbchecks;"No data in HDB table"]];                                                           /Error log if check fails here
  checks                                                                                                                           /Returns checks dictionary
 }
.dg.handlers[`hdb]:.dg.is_hdb_ok                                                                                                   /Adds to handlers dictionary
.dg.tpstate:(0Np;0Nj)                                                                                                              /Set initial state of TP to 0
.dg.is_tickerplant_ok:{
  if[(`time$.z.p)<00:01:00.00;.dg.tpstate:(0Np;0)];                                                                                /Set state of TP to 0 if it is a new day
    s:$[.u.i>.dg.tpstate[1];1b;0b];                                                                                                /Check if log file message count is increasing against previous count  
    .dg.tpstate:(.z.p;.u.i);:s}                                                                                                    /Save new count as tpstate and show result
.dg.handlers[`tickerplant]:.dg.is_tickerplant_ok                                                                                   /Adds to handlers dictionary

