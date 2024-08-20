
\d .idb
hdbdir:hsym @[value;`hdbdir;`:hdb];                                        /-set hdb directory. Will be used for reading symbols from sym file
partitiontype:@[value;`partitiontype;`date];                               /-set type of partition (defaults to `date)
getpartition:@[value;`getpartition;                                        /-function to determine the partition value
               {{@[value;`.idb.currentpartition;
                   (`date^partitiontype)$.proc.cd[]]}}];

currentpartition:getpartition[];
