// IPC connection parameters
.servers.CONNECTIONS:`wdb;
.servers.USERPASS:`admin:admin;
// Paths to process CSV and temp HDB directory
processcsv:getenv[`KDBTESTS],"/tailer/savedown/process.csv";
temphdbdir:hsym `$getenv[`KDBTESTS],"/tailer/savedown/tmphdb/";
testlogdb:"testlog";
systemcall:"ls ",1_string[temphdbdir]

// Test tables
testtrade:([]time:.z.p - 01:00+til 50;sym:50?`IBM`GOOG`MSFT`AAPL;price:50?100.00;size:50?150;stop:50?0 1; cond:50?.Q.A;ex:50?`O`N;size:50?`buy`sell)
testquote:([]time:.z.p-01:00+til 50;sym:50?`AAPL`MSFT`GOOG`IBM;bid:50?500.0;ask:50?500.0;bsize:50?200;asize:50?200;mode:50?.Q.A;ex:50?`N`O;src:50?`BARX`DB`GETGO`SUN)
