// reload function
reload:{[pt]
	.lg.o[`reload; "reloading IDB for partition: ",string pt];
	//`sym set get .idb.dbpath};
 };

\d .idb
gmttime:@[value;`gmttime;1b];                                              /-define whether the process is on gmttime or not
partitiontype:@[value;`partitiontype;`date];                               /-set type of partition (defaults to `date)
getpartition:@[value;`getpartition;                                        /-function to determine the partition value
			   {{@[value;`.idb.currentpartition;
				   (`date^partitiontype)$(.z.D,.z.d)gmttime]}}];

currentpartition:getpartition[];
