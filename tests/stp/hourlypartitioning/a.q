${TORQHOME}/torq.sh start discovery1 -csv ${testpath}/process.csv
${TORQHOME}/torq.sh stop discovery1 -csv ${testpath}/process.csv
${TORQHOME}/torq.sh stop all -csv ${testpath}/process.csv
q ${TORQHOME}/torq.q -proctype test -procname test1 -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q -procfile ${testpath}/process.csv -debug -dataaccess ${testpath}/tableproperties.csv -p 4445


.servers.startup[];
startproc["stp1"];
.proc.sys "sleep 3";
stpHandle:gethandle[`stp1];
logdir:1_string stpHandle(`.stplg.dldir);
.proc.sys "sleep 3";
.os.md hdbdir;
.os.md .Q.dd[hdbdir;`0];
startproc each ("sctp1";"wdbenum";"hdb1";"gateway1";"idbenum";"rdb1";"sort1");

.proc.sys "sleep 3";
sctpHandle:gethandle[`sctp1];
wdbHandle:gethandle[`wdbenum];
idbHandle:gethandle[`idbenum];
gwHandle:gethandle[`gateway1];
hdbHandle:gethandle[`hdb1];
rdbHandle:gethandle[`rdb1];
sort1:gethandle[`sort1];

wdbHandle(set;`.wdb.numtab;`quote`trade!7 8);
neg[gwHandle](`.gw.asyncexec;"select from trade";`idb);0~count gwHandle[];
0"stpHandle @/: `.u.upd ,/: ((`trade;testtrade);(`quote;testquote))";
.proc.sys "sleep 2";
// ***************************
wdbHandle`.wdb.eodwaittime
.servers.SERVERS
neg[gwHandle](`.gw.asyncexec;"select from trade";`idb);gwHandle[]
wdbHandle`trade
// *************************** END

neg[gwHandle](`.gw.asyncexec;"select from trade where int=maptoint[`GOOG]";`idb);5~count gwHandle[];
neg[gwHandle](`.gw.asyncexec;"select from quote_iex";`idb);0~count gwHandle[];

// ***************************
.servers.SERVERS
@[;`attributes]select first attributes from .servers.SERVERS where procname=`rdb1
/
partition  tables                                                  
-------------------------------------------------------------------
2024092710 heartbeat logmsg packets quote quote_iex trade trade_iex
\
@[;`attributes]select first attributes from .servers.SERVERS where procname=`hdb1
/
partition tables          
--------------------------
0         heartbeat logmsg
\
// *************************** END

//wdbHandle(`.u.end;`.wdb.currentpartition)
stpHandle".stplg.checkends .z.p+60*60*1000000000";
/ stpHandle".stplg.checkends .z.p+2*60*60*1000000000";
/ stpHandle".stplg.checkends .z.p+3*60*60*1000000000";
/ stpHandle".stplg.checkends .z.p+4*60*60*1000000000";
/ stpHandle".stplg.checkends .z.p+5*60*60*1000000000";


//wdbHandle"endofperiod[.wdb.getpartition[];1+.wdb.getpartition[];()!()]";
.proc.sys "sleep 2";
hdbHandle".Q.chk[`:.]";
neg[gwHandle](`.gw.asyncexec;"select from trade where sym=`GOOG";`hdb);5~count gwHandle[];
// ***************************
gwHandle`.gw.eod
.servers.SERVERS
@[;`attributes]select first attributes from .servers.SERVERS where procname=`rdb1
/
partition  tables                                                  
-------------------------------------------------------------------
2024092710 heartbeat logmsg packets quote quote_iex trade trade_iex
\
@[;`attributes]select first attributes from .servers.SERVERS where procname=`hdb1
/
partition tables          
--------------------------
0         heartbeat logmsg
\
.servers.retry[]
.servers.SERVERS

.servers.reset[]
.servers.startup[]
gwHandle"@[;`attributes]select first attributes from .servers.SERVERS where procname=`rdb1"
gwHandle"@[;`attributes]select first attributes from .servers.SERVERS where procname=`hdb1"
gwHandle `.gw.servers
neg[gwHandle](`.gw.asyncexec;"select from trade where int=maptoint[`GOOG]";`idb);5~count gwHandle[]
neg[gwHandle](`.gw.asyncexec;"select from trade ";`hdb`idb`rdb);gwHandle[]
// *************************** END
// ***************************
.dataaccess.init[` sv (hsym `$getenv[`TORQHOME]),`$"tests/stp/hourlypartitioning/tableproperties.csv"];
rdbHandle(.dataaccess.init;` sv (hsym `$getenv[`TORQHOME]),`$"tests/stp/hourlypartitioning/tableproperties.csv");
hdbHandle(.dataaccess.init;` sv (hsym `$getenv[`TORQHOME]),`$"tests/stp/hourlypartitioning/tableproperties.csv");
gwHandle(.dataaccess.init;` sv (hsym `$getenv[`TORQHOME]),`$"tests/stp/hourlypartitioning/tableproperties.csv");
querydict:`tablename`starttime`endtime`aggregations`procs`getquery!(`quote;2024.09.20D00:00:00.000000000;2024.09.21D21:00:00.000000000;`max`min!(`ask`bid;`ask`bid);(`hdb);1b)
q:gwHandle(`.dataaccess.getdata;querydict)
querydict:`tablename`starttime`endtime`aggregations`procs!(`quote;2024.09.25D00:00:00.000000000;2024.09.26D21:00:00.000000000;`max`min!(`ask`bid;`ask`bid);(`hdb))
gwHandle(`.dataaccess.getdata;querydict)

hdbHandle q 1

gwHandle`.dacustomfuncs.partitionrange
hdbHandle`.dacustomfuncs.partitionrange
hdbHandle(set;`.dacustomfuncs.partitionrange;{[tabname;hdbtimerange;prc;timecol]
    // Get the partition fields from default rollover 
    //hdbtimerange:.dacustomfuncs.rollover[tabname;;prc] each hdbtimerange+00:00;
    partfield:@[value;`.Q.pf;`];
    C:?[.checkinputs.tablepropertiesconfig;((=;`tablename;(enlist tabname));(=;`proctype;(enlist prc)));();(1#`ptc)!1#`primarytimecolumn];
    // Output the partitions allowing for non-primary timecolumn
    @[hdbtimerange;1;+;any timecol=raze C[`ptc]];
    //if[partfield=`int;hdbtimerange:`long$`timestamp$hdbtimerange];
    if[partfield=`int;hdbtimerange:.ps.periodtohour each `timestamp$hdbtimerange];
    :hdbtimerange})


hdbHandle(set;`.dacustomfuncs.partitionrange;{[tabname;hdbtimerange;prc;timecol]
    hdbtimerange:.dacustomfuncs.rollover[tabname;;prc] each hdbtimerange+00:00;
    hdbtimerange})

hdbHandle(`.dataaccess.checktablename;querydict)
(hdbHandle(`.dataaccess.checktablename;querydict))`tableproperties
((hdbHandle(`.dataaccess.checktablename;querydict))`tableproperties)`getpartitionrange

200001010
2000.01.010
(2147483647+1)%65536

querydict:`tablename`starttime`endtime`aggregations`procs!(`quote;2024.09.20D00:00:00.000000000;2024.09.21D21:00:00.000000000;`max`min!(`ask`bid;`ask`bid);(`hdb`rdb))
gwHandle".checkinputs.checkprocs:{[dict;parameter] dict};"
gwHandle(`.dataaccess.getdata;querydict)

querydict:`tablename`starttime`endtime`aggregations!(`trade;2024.09.23D00:00:00.000000000;2024.09.24D21:00:00.000000000;`max`min!(`price;`price))
querydict:`tablename`starttime`endtime`aggregations`getquery!(`trade;2024.09.20D00:00:00.000000000;2024.09.21D21:00:00.000000000;`max`min!(`price;`price);1b)
gwHandle(`.dataaccess.getdata;querydict)
gwHandle`.dataaccess.getdata
gwHandle`.dataaccess.logging
gwHandle`.dataaccess.stats
gwHandle(`.checkinputs.checkinputs;querydict)
gwHandle`.checkinputs.checkinputsconfig
`.checkinputs.checkprocs

stopproc each ("rdball";"rdbsymfilt";"rdbonetab")
gwHandle(`.checkinputs.checkinputs;querydict)
gwHandle(`.dataaccess.partdict;querydict)
gwHandle`.gw.servers
// *************************** END



0=sum idbHandle@/: {raze ("count select from ";x)} each string wdbHandle(`.wdb.tablelist;());
neg[gwHandle](`.gw.asyncexec;"select from trade";`idb);0~count gwHandle[];
0"stpHandle @/: `.u.upd ,/: ((`trade;testtrade);(`quote;testquote))";
.proc.sys "sleep 2";
neg[gwHandle](`.gw.asyncexec;"select from trade where int=maptoint[`GOOG]";`idb);5~count gwHandle[];
0"stpHandle @/: `.u.upd ,/: ((`trade;enlist[(count[testtrade[0]]#`round2)],1_testtrade);(`quote;testquote))";
.proc.sys "sleep 2";
neg[gwHandle](`.gw.asyncexec;"select from trade where int=maptoint[`round2]";`idb);10~count gwHandle[];
// ***************************


// *************************** END
stpHandle".stplg.checkends .z.p+2*60*60*1000000000";
0"stpHandle @/: `.u.upd ,/: ((`trade;enlist[(count[testtrade[0]]#`round3)],1_testtrade);(`quote;testquote))";
0"stpHandle @/: `.u.upd ,/: ((`trade;enlist[(count[testtrade[0]]#`round3)],1_testtrade);(`quote;testquote))";
neg[gwHandle](`.gw.asyncexec;"select from trade";`hdb);gwHandle[]
neg[gwHandle](`.gw.asyncexec;"select from trade";`rdb);gwHandle[]
neg[gwHandle](`.gw.asyncexec;"select from trade";`idb);gwHandle[]
gwHandle"select procname,attributes[`partition] from .servers.SERVERS where proctype in `hdb`idb`rdb"
/
procname x                    
------------------------------
rdb1     2024092717 2024092718
hdb1     ,0                   
idbenum  ,2024092716          
\
gwHandle"select procname,attributes[`partition] from .gw.servers where proctype in `hdb`idb`rdb"
gwHandle"select from .servers.SERVERS where procname=`idbenum"
rdbHandle"."
rdbHandle".proc.getattributes"
hdbHandle".proc.getattributes"
idbHandle".proc.getattributes"
rdbHandle".rdb.getpartition[]"


hclose each (wdbHandle;gwHandle;idbHandle);
kill9proc each ("wdbenum";"hdb1";"gateway1";"idbenum";"rdb1";"sctp1";"sort1";"stp1");

.os.deldir logdir;
.os.deldir 1_string hdbdir;
.os.deldir 1_string wdbdir;

1+1
hourtoperiod
{x:string x;(0D1*"I"$x[8 9])+(0D+"D"$"." sv enlist[4#x;x[4 5];x[6 7]])} 2024092611
{if[(x<2000010100);:`timestamp$0];x:string x;(0D1*"I"$x[8 9])+(0D+"D"$"." sv enlist[4#x;x[4 5];x[6 7]])} 2024092611
{if[(x<2000010100);:`timestamp$0];x:string x;(0D1*"I"$x[8 9])+(0D+"D"$"." sv enlist[4#x;x[4 5];x[6 7]])} 2100010100
{if[(x<2000010100);:`timestamp$0];x:string x;(0D1*"I"$x[8 9])+(0D+"D"$"." sv enlist[4#x;x[4 5];x[6 7]])} 0

"I"$"200000"
.z.p
.z.p+3*0D1
"I"$"03"
ssr[;" ";"0"] 10$"00"



