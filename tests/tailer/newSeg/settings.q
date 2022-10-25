// IPC connection parameters
.servers.CONNECTIONS:`segmentedtickerplant`sort`gateway`rdb`rdb2`hdb`tailer_seg1`tr_seg1`tailer_seg2`tr_seg2;
// Paths to process CSV and temp HDB directory
processcsv:getenv[`KDBTESTS],"/tailer/newSeg/process.csv";
temphdbdir:hsym `$getenv[`KDBTESTS],"/tailer/newSeg/tmphdb/";
testlogdb:"testlog";
systemcall:"ls ",1_string[temphdbdir]
// Test tables