\d .cmp

inputcsv:@[value;`inputcsv;.proc.getconfigfile["compressionconfig.csv"]];      // compression config file to use
hdbpath:@[value;`hdbpath;`:hdb]                                                 // hdb directory to compress
maxage:@[value;`maxage;365]                                                     // the maximum date range of partitions to scan
exitonfinish:@[value;`exitonfinish;1b]						// exit the process when compression is complete

if[not count key hsym .cmp.hdbpath; .lg.e[`compression; err:"invalid hdb path ",(string .cmp.hdbpath)];'err];

/- run the compression
.cmp.compressmaxage[hsym .cmp.hdbpath;.cmp.inputcsv;.cmp.maxage]

if[exitonfinish; .lg.o[`compression; "finished compression"]; exit 0]
