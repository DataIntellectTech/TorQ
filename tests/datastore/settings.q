// IPC connection parameters
.servers.CONNECTIONS:`segmentedtickerplant`rdb;

// rmdtfromgetpar function in processes/rdb.q
.rdb.rmdtfromgetpar:{[date] 
    .rdb.rdbpartition:: .rdb.rdbpartition except date;
    .lg.o[`rdbpartition;"rdbpartition contains - ","," sv string .rdb.rdbpartition];
    }
