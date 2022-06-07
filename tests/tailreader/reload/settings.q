// Paths to process CSV and temp HDB directory
processcsv:getenv[`KDBTESTS],"/tailreader/reload/process.csv";
tempwdbdir:hsym `$getenv[`KDBTESTS],"/tailreader/reload/testwdb/";
testlogdb:"testlog";
systemcall:"ls ",1_string[temphdbdir]
currentpartition:2022.06.01
segmentid:1
