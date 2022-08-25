// IPC connection parameters
.servers.CONNECTIONS:`segmentedtickerplant`sort`gateway`rdb`hdb`tailer_seg1`tr_seg1
.servers.USERPASS:`admin:admin;
// Paths to process CSV and temp HDB directory
processcsv:getenv[`KDBTESTS],"/tailer/savedown/process.csv";
temphdbdir:hsym `$getenv[`KDBTESTS],"/tailer/savedown/tmphdb/";
testlogdb:"testlog";
systemcall:"ls ",1_string[temphdbdir]
// Test tables
