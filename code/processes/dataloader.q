//this process is used to take csv files of factset data and save them down to our hdb location
//the factset data we are current getting is level 1 and level 2

\d .dl

//level 1 quote meta
l1QuoteTypes: "SID*JFJJFFJSFJSFSJJSSFFSFFSSSSTTTSFSSDTJSJP";

//what is this?
l1QuoteNames: `TICKER`MSG_TYPE`DATE`TIME`SEQUENCE`LAST_PRICE`LAST_VOL`CVOL`VWAP`BID`BID_VOL`BID_EXCH`ASK`ASK_VOL`ASK_EXCH`MID`SECURITY_STATUS`MSG_BITMASK`ORIG_SEQUENCE`TRADE_CONDITION`VENUE`ASK_YIELD`BID_YIELD`BUY_ID`CURRENT_YIELD`MID_YIELD`ORDER_CODE`REPORTING_SIDE`SELL_ID`PRODUCT`MID_TIME`BID_TIME`ASK_TIME`SECURITY_TYPE`YIELD_PRICE`ISO_CODE`LAST_EXCH`LAST_DATE`LAST_TIME`ORDER_NUM`ISO`CCVOL`UTC_TIME

//what are these
quoteNames: `TICKER`ISO_CODE`DATE`TIME`BID_OPEN_PRC`BID_CLOSE_PRC`BID_SUM_VOL`ASK_OPEN_PRC`ASK_CLOSE_PRC`ASK_SUM_VOL`COUNT`MEDIAN_SPREAD`UTC_TIME
tradeNames: `ISO_CODE`TICKER`DATE`TIME`TRADE_OPEN`TRADE_HIGH`TRADE_LOW`TRADE_CLOSE`TRADE_VOLUME`SECURITY_TYPE`TRADE_NUMBER`TRADE_VWAP`UTC_TIME

//level 2 tables col types
quoteTypes: "SSD*FFJFFJJFP"
tradeTypes: "SSD*FFFFJJJFP"


seenFilesPath: hsym `$(getenv `TORQDATAHOME), "/data/factset_data/seenfiles.txt"
seen: ()
files:()


hdbDirectory:hsym `$(getenv `KDBHDB);  //hdb location
fifoDirectory:(getenv `TORQDATAHOME), "/data/factset_data/fifo";  //location of the csv files
dirPath:"/home/shared/factsetdata/minutebars/";
batchSize:20;

//used record what files have been saved down to disk, saves the file path
saveSeen:{
    seenFilesPath set .dl.seen;
 };

//loads in the file paths  which have been previously read
loadSeen:{
    if[0 > count key seenFilesPath;
        .dl.seen: get seenFilesPath;
    ];
 };

//discovers the new files that have been sent in
getNewFiles:{[dir]
    / find all gzip csv files
    allFiles: `${":",x} each system "find ", dir, " -type f -name '*.csv.gz'";  //find all gzip csv files
    new: allFiles except .dl.seen; //only files we have not seen yet
    .lg.o[`dataWorker;"Getting processed files"];
    if[(count new) > 0;
        .dl.seen: .dl.seen , new;
        .lg.o[`dataWorker;"Appending to seenFiles.txt"]
        .dl.saveSeen[];
    ];
    new;
 };

// Files should be checked every x seconds to see if any files are new. seenFiles.txt should be looked at and compared with current files. If any changes, add files in x batches
createTable:{[tabName; tabType]
  $[(tabType = `quotes) & not any tabName in key `.dl;    // Create quote table if it does not already exist
      @[`.dl; tabName; :; flip quoteNames!quoteTypes$\:()];     
    (tabType = `trades) & not any tabName in key `.dl;    // Create trade table if it does not already exist
      @[`.dl; tabName; :; flip tradeNames!tradeTypes$\:()]
    ]
 };

//give description
parsePath:{[path]
  parts: "/" vs string path;    // Split path
  tabType:  raze parts where (parts like "quotes") or parts like "trades";  // Extract table type
  dataTypes:  raze parts where (parts like "minutebars") or parts like "l1";  // Extract table type
  country: parts[(count parts) - 5];  // Extract country
  tabName: (`$tabType,"_",country;`$tabType)    // Concatenate table name
 };

// Reads file from system 
readFile:{[file]
    system "rm -f ", fifoDirectory, " && mkfifo ", fifoDirectory;   // System command to remove and create fifo
    system raze ("gunzip -cf ", (1_string file), " > ", fifoDirectory, " &");    // System command to extract csv file paths

    tabDetails:parsePath[file];   // Determine if quote or trade
    tabName:tabDetails[0];
    tabType:tabDetails[1];
    createTable[tabName;tabType];   // Create table if not already created
    columnTypes:$[`quotes = tabType; quoteTypes; `trades = tabType; tradeTypes; 0N];  // Choose column types

    .Q.fps[{[columnTypes; tabName; csvFile]   // Stream data through fifo
      t: (columnTypes; ",") 0:1_csvFile;    // Extract data from csv
      t[3]:{"T"$"0"^-9$ x} each t[3];     // Parsing time column
      tab: value `.dl, tabName;   // Extracting table name
      insert[`.dl .Q.dd'tabName; t];   // Inserting data into table
      }[columnTypes;tabName]
     ]hsym `$fifoDirectory;
    .lg.o[`dataWorker;"File reading complete"];

 };

writeData:{[t;d]
  (` sv .Q.par[hdbDirectory;d;t],`) 
    upsert .Q.en[hdbDirectory;] 
    delete DATE from (select from t where DATE = d);    // Write data to disk
  .lg.o[`dataWorker;"Writing table to disk"];
  `TICKER`ISO_CODE`TIME xasc .Q.par[hdbDirectory;d;t];    // Sort data on disk
  @[.Q.par[hdbDirectory;d;t];`TICKER;`p#];   // Add p#
  .lg.o[`dataWorker;"Sorting data in HDB"];
 };

processFiles:{[files; batchSize]
  n: count files;   
	.lg.o[`dataWorker;"Process Started"];
  .lg.o[`dataWorker;"File Count: ", string n];
  batches: ceiling n % batchSize;   // No of files / Batch Size to get number of iterations needed
  .lg.o[`dataWorker;"Batches: ", string batches];
  show n;

 {
    start: x * batchSize;    
    size: min(batchSize; y - start);
    idxs: start + til size;
    currentFiles: files idxs;     // logic to split each of the files into lists of indexes

	  .lg.o[`dataWorker;"Batch Started"];
    results: @[readFile; ;{.lg.e[`dataWorker;"Could not read file"]}] each currentFiles;

    currentTables: .Q.dd[`.dl;] each tables `.dl;   // Get current tables in process

    @[{writeData[x;] each exec distinct DATE from x}; ;{.lg.e[`dataWorker;"Could not write file"]}] each currentTables;    // Write data for each date and each table
    {delete x from `.dl} each tables `.dl;    // Delete current batch tables from memory
    .Q.gc[];    // Return memory
  }[;n] each til batches;
 };

// Main Function to run
runDataLoader:{[dir] 
  @[loadSeen; (); {.lg.e[`dataWorker;"Could not load seen files"]}]    // Load seen files
  .dl.files: @[getNewFiles; dir;{.lg.e[`dataWorker;"Could not get files in directory"]}];    // Get new files in directory

  if[(count files) > 0;
    processFiles[files; batchSize];
    .lg.o[`dataWorker;"No new files to process"]
  ]
 };

runDataLoader[dirPath];
\d .
