//-QUnit testing of the TorQ RDB

//-Set up discovery service
.servers.USERPASS:`admin:admin;
.servers.startup[];
/.servers.CONNECTIONS:`rdb`segmentedtickerplant`gateway`feed;
.servers.CONNECTIONS:`rdb`segmentedtickerplant`gateway; //-tosee if we can push data to rdb via tp
//-Move into rdbTest namespace
system "d .rdbTest"

//-Get the handle to the RDB via discovery; explicit return to store the variable h
beforeNamespace_GetHandleToRDB:{
    h::(exec first w from .servers.getservers[`proctype;`rdb;()!();1b;1b])
    };

//-Some simple RDB tests on the actual TorQ stack 

//-1-Check that the trade table has a count > 0 for the current day: Could set count before and recount
testRDBTradeCount:{ 
    r:h(get;"count select from trade where time.date=.z.d");
    .qunit.assertThat[r;>;0;"RDB trade table has a count > 0"];
    };

//-2-Check that the quote table has a count > 0 for the current day
testRDBQuoteCount:{
    r:h(get;"count select from quote where time.date=.z.d");
    .qunit.assertThat[r;>;0;"RDB quote table has a count > 0"];
    };

//-3-Check that the trade table has cleared out after EOD i.e. last date and first date are same
testRDBClearsTradeAtEOD:{
    r1:h(get;"select first time.date from trade");
    r2:h(get;"select last time.date from trade");
    .qunit.assertEquals[r1;r2;"RDB trade table cleared yesterday"]
    };

//-4-Check that the quotee table has cleared out after EOD i.e. last date and first date are same
testRDBClearsQuoteAtEOD:{
    r1:h(get;"select first time.date from quote");
    r2:h(get;"select last time.date from quote");
    .qunit.assertEquals[r1;r2;"RDB quote table cleared yesterday"]
    };

//-5-publish data to tickerplant
//***********************************************************************
//-idk if this is really testing
//-might have to get to stp first then use that to feed fake data to rdb?
//***********************************************************************

//-Closing the connection 
afterNamespaceRDB:{hclose h};
