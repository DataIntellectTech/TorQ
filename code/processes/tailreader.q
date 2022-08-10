\d .tr 
partitiontype:@[value;`partitiontype;`date];                               /-set type of partition (defaults to `date)
gmttime:@[value;`gmttime;1b];                                              /-define whether the process is on gmttime or not
determinepartition:{{@[value;`.tr.currentpartition;                        /-function to determine the partition value
    (`date^partitiontype)$(.z.D,.z.d)gmttime]}
  }; 
getpartition:@[value;`getpartition;determinepartition[]];                  /-check if partition value exists and if not generate one
taildir:hsym `$getenv`KDBTAIL						   /-load in taildir env variables
.tr.currentpartition:.tr.getpartition;					   /-obtain  partition value
basedir:(raze/)1_string[.tr.taildir],"/wdb",string .ds.segmentid,"/"       /-define associated tailer base directory
wdbdir:`$ basedir,string currentpartition                                      /-define IDB direction

\d .
endofday:{[pt]
  /- end of day function that will be triggered by EOD Sorter once IDB is copied to HDB
  /-  updates partition and loads in next days partition
  .lg.o[`eod;"End of day message received - ",spt:string pt];
    currentpartition::pt+1;
    reload[];
  }

reload:{
  /- function to define the access table and IDB dir and then reload both tables
  /- reload is triggered by tailer after savedown occurs
  basedir::(raze/)1_string[.tr.taildir],"/wdb",string .ds.segmentid,"/";
  wdbdir::`$ basedir,string currentpartition;
  accesstabdir::`$ basedir,"access";
  
 @[.Q.l ;wdbdir;{.lg.e[`load;"Failed to load intradayDB with error: ",x]}];
 @[.Q.l ;accesstabdir;{.lg.e[`load;"Failed to load tailer accesstable with error: ",x]}];
  load hsym `$basedir,"sym"
  }

basedir:.tr.basedir								   /-bring basedir variable into default namespace
wdbdir:.tr.wdbdir							           /-bring wdbdir variables into default namespace
currentpartition:.tr.currentpartition																	 /- bring currentpartition into default namespace 
$[not ()~ key hsym wdbdir;reload[];.lg.o[`load;"No IDB present for this date"]];  /-checks to see if the IDB exists and if so loads in the accestable and IDB on tailreader startup
																																									/- if not logs as INF not ERR as it is expected on first time use that there is no data to load in

