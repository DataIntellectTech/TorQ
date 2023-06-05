.servers.USERPASS:`admin:admin; //-Setting up TorQ discovery service credentials
.servers.startup[] //-Initialise the connections

system "d .rdbTest" //-Moving into rdbTest namespace

test_TickerplantType:{
     r:.rdb.tickerplanttypes;
     .qunit.assertThat[r;~;`segmentedtickerplant;"Testing that the Tickerplant is a Segmentedtickerplant"];
     };

test_RDBSubscriptionTabs:{
    r:.rdb.subscribeto;
    .qunit.assertThat[r;~;`;"Testing that the RDB is subscribed to `(all tables)"];
    };

test_RDBSubscriptionSyms:{
   r:.rdb.subscribesyms;
   .qunit.assertThat[r;~;`;"Testing that the RDB is subscribed to `(all syms)"];
   };

test_EODSaveTabs:{
   r:.rdb.savetables;   
   .qunit.assertThat[r;~;1b;"Testing that the tables will be saved at EOD"];
   };

test_RDBUpdIsInsert:{
    r:.rdb.upd;
    .qunit.assertThat[r;~;insert;"Testing upd is defined as insert"];
    };

test_Ignorelist:{
    r:.rdb.ignorelist;
    .qunit.assertThat[r;~;`heartbeat`logmsg;"Testing the heartbeat and logmsg tables will be ignored when saving to disk"];
    };


//-Unit testing of upd function 
beforeNamespace_GetHeartbeatCount:{  
    hbCount::count .hb.heartbeat; //-Finding the count of the heartbeat table before any updates
    };

test_HeartbeartPopulating:{  
    .rdb.upd[`.hb.heartbeat;(.z.p;`test;`rdb1;1;1i;`testhost;1i)]; //-Update heartbeat table via upd
    r:count .hb.heartbeat;  //-Count the updated heartbeat table
    .qunit.assertThat[r;>;hbCount;"Testing the heartbeat table has a new row published after using upd function"]
    };


//-Integration testing of upd function
beforeNamespace_SaveTPHandle:{ //-Getting the handle to the segmentedtickerplant
    h::first .sub.getsubscriptionhandles[.rdb.tickerplanttypes;();()!()]`w; //-Getting the  handle to the segmentedtickerplant
    };

beforeNamespace_saveQuoteTradeCount:{ 
    quoteTab::h(`.u.sub;`quote;`) 1;  //-Subscribing to quote table from STP
    tradeTab::h(`.u.sub;`trade;`) 1;  //-Subscribing to trade table from STP
    quoteCount::count .rdbTest.quoteTab; //-Counting quote table
    tradeCount::count .rdbTest.tradeTab; //-counting trade table
    };

test_QuotePopulating:{
    .rdb.upd[`.rdbTest.quoteTab;(.z.p;`testSym;1f;1f;1j;1j;"t";"t";`testSrc)]; //-Update the quote table via upd
    r:count .rdbTest.quoteTab; //-Count the updated quote table
    .qunit.assertThat[r;>;quoteCount;"Testing that the quote table is being populated using upd"]
    };

test_TradePopulating:{
    .rdb.upd[`.rdbTest.tradeTab;(.z.p;`testSym;1f;1i;1b;"t";"t";`testSrc)];  //-Update the trade table via upd
    r:count .rdbTest.tradeTab; //-Count the updated trade table
    .qunit.assertThat[r;>;tradeCount;"Testing that the trade table is being populated using upd"]
    };

afterNamespace_CloseTPHandle:{ 
    hclose h; //-Closing the handle to the segmentedtickerplant
    };
