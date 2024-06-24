// reload function
reload:{[pt]
    .lg.o[`reload; "reloading IDB for partition: ",string pt];
    //`sym set get .idb.dbpath};
 };

\d .idb
partitiontype:@[value;`partitiontype;`date];                               /-set type of partition (defaults to `date)
getpartition:@[value;`getpartition;                                        /-function to determine the partition value
               {{@[value;`.idb.currentpartition;
                   (`date^partitiontype)$.proc.cd[]]}}];

currentpartition:getpartition[];
