/-TorQ wdb process - based upon w.q 
/http://code.kx.com/wsvn/code/contrib/simon/tick/w.q
/-subscribes to tickerplant and appends data to disk after the in-memory table exceeds a specified number of rows
/-the row check is set on a timer - the interval may be specified by the user
/-at eod the on-disk data may be sorted and attributes applied as specified in the sort.csv file

/- load parameters & functions from common script.
.proc.loadf [getenv[`KDBCODE],"/wdb/common.q"]

/- make sure to request connections for all the correct types
.servers.CONNECTIONS:(distinct .servers.CONNECTIONS,.wdb.hdbtypes,.wdb.rdbtypes,.wdb.gatewaytypes,.wdb.tickerplanttypes,.wdb.sorttypes,.wdb.sortworkertypes) except `

/- set the replay upd 
.lg.o[`init;"setting the log replay upd function"];
upd:.wdb.replayupd;
/ - clear any wdb data in the current partition
.wdb.clearwdbdata[];
/- initialise the wdb process
.wdb.startup[];
/ - start the timer if datastriping off
$[.ds.datastripe;.lg.o[`data;"datastriping on - savedown to ",(string .wdb.savedir)," disabled"];.wdb.saveenabled;.wdb.starttimer[]];

/- use the regular up after log replay
upd:.wdb.upd
