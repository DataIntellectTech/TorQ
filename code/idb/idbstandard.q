
\d .idb
hdbdir:hsym @[value;`hdbdir;`:hdb];                                        /-set hdb directory. Will be used for reading symbols from sym file
savedir:hsym @[value;`savedir;`:wdb];                                      /-set wdb directory.
partitiontype:@[value;`partitiontype;`date];                               /-set type of partition (defaults to `date)
getpartition:@[value;`getpartition;                                        /-function to determine the partition value
               {{@[value;`.idb.initialpartition;
                   (`date^partitiontype)$.proc.cd[]]}}];

initialpartition:getpartition[];                                           /-at startup the IDB will try to load this partition. Later on the WDB instructs the IDB which partition to load.
setupsuccess:0b;                                                           /-the IDB is only considered to be successfully setup if it was able to load the underlying database(there is data and sym file)

\d .proc
trap:1b;                                                                   /-the IDB won't fail, it just signals error on its stderr. This means that the process will be still alive
                                                                           /-when there is no database behind. This will prevent IDB failures during EOD merging of the WDB.
