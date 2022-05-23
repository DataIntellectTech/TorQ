\d .tr 
partitiontype:@[value;`partitiontype;`date];                               /-set type of partition (defaults to `date)
gmttime:@[value;`gmttime;1b];                                              /-define whether the process is on gmttime or not
getpartition:@[value;`getpartition;
  {{@[value;`.wdb.currentpartition;
    (`date^partitiontype)$(.z.D,.z.d)gmttime]}}];                      /-function to determine the partition value
segmentid: "J"$.proc.params[`segid]
td:hsym `$getenv`KDBTAIL																							 /-load in taildir env variables
.tr.currentpartition:.tr.getpartition[];															 /-obtain  partition value

\d .
endofday:{[pt]
  /- end of day function that will be triggered by EOD Sorter once IDB is copied to HDB
  /-  updates partition and loads in next days partition
  /*****EOD timing needs to be sorted as can potentially have two days data in IDB around EOD*****
  .lg.o[`eod;"end of day message received - ",spt:string pt];
    currentpartition::pt+1;
    reload[];
  }


reload:{
  /- function to define the access table and IDB dir and then reload both tables
  /- reload is triggered by tailer after savedown occurs
  dir:(raze/)1_string[.tr.td],"/wdb",string .tr.segmentid,"/";
  wdbdir::`$ dir,string currentpartition;
  accesstabdir::`$ dir,"access";
  @[.Q.l ;wdbdir;{.lg.e[`load;"Failed to load intradayDB with error: ",x]}];
  @[.Q.l ;accesstabdir;{.lg.e[`load;"Failed to load tailer accesstable with error: ",x]}];
 }

currentpartition:.tr.currentpartition																	 /- bring currentpartition into default namespace 
reload[]																															 /- reload accestable and IDB on tailreader startup
