// IPC connection parameters
.servers.CONNECTIONS:`segmentedtickerplant`sort`gateway`hdb`tailer_seg1`tr_seg1`tailer_seg2`tr_seg2`centraltailsort1`tailsort1_1`tailsort1_2`tailsort2_1`tailsort2_2
// Paths to process CSV and temp HDB directory
processcsv:getenv[`KDBTESTS],"/tailsort/endofday/process.csv";

hdbpath:getenv[`KDBHDB],"/";
taildir:getenv[`TORQDATA],"/taildir";
tailer1path:getenv[`TORQDATA],"/taildir/tailer1";
tailer2path:getenv[`TORQDATA],"/taildir/tailer2";

// Test tables
