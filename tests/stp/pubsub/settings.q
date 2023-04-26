// IPC connection parameters
.servers.CONNECTIONS:`pubsub;
.servers.USERPASS:`admin:admin;

// Path to table schemas
schemapath:getenv[`TORQHOME],"/database.q";

// Keyed sub table
ksubtab:1!enlist `tabname`filters`columns!(`trade;"sym in `GOOG`AMZN,price>80";"time,sym,price");

// Define local functions to be called from pubsub
endofperiod:{[x;y;z] .tst.eop:@[{1+value x};`.tst.eop;0]};
endofday:{[x;y] .tst.eod:@[{1+value x};`.tst.eod;0]};
upd:{[t;x] .tst.upd:@[{1+value x};`.tst.upd;0]};

// Test trade update
testtrade:(.z.p;`sym;90f;50;1b;"H";"I";`ask);