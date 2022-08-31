\d .tr
partitiontype:@[value;`partitiontype;`date];                               /-set type of partition (defaults to `date)
gmttime:@[value;`gmttime;1b];                                              /-define whether the process is on gmttime or not
determinepartition:{@[value;`.tr.currentpartition;                         /-function to determine the partition value
  (`date^partitiontype)$(.z.D,.z.d)gmttime]
  };
getpartition:@[value;`getpartition;determinepartition[]];                  /-check if partition value exists and if not generate one
segmentid: "J"$.proc.params[`segid]
taildir:hsym `$getenv`KDBTAIL                                              /-load in taildir env variables
currentpartition:getpartition;                                             /-obtain  partition value
basedir:(raze/)1_string[.tr.taildir],"/tailer",string .tr.segmentid,"/"    /-define associated tailer base directory
wdbdir:`$ basedir,string currentpartition                                  /-define IDB direction

\d .
endofday:{[pt]
  /- end of day function that will be triggered by EOD Sorter once IDB is copied to HDB
  /-  updates partition and loads in next days partition
  .lg.o[`eod;"End of day message received - ",spt:string pt];
  .tr.currentpartition:pt+1;
  reload[];
  }

reload:{
  /- function to define the access table and IDB dir and then reload both tables
  /- reload is triggered by tailer after savedown occurs
  .tr.wdbdir:`$ .tr.basedir,string .tr.currentpartition;
  accesstabdir:`$ (string .tr.wdbdir),"/access";
  .lg.o[`load;"Loading intradayDB"];
  @[.Q.l ;.tr.wdbdir;{.lg.e[`load;"Failed to load intradayDB with error: ",x]}];
  .lg.o[`load;"intradayDB loaded"];
  .lg.o[`load;"loading accesstable"];
  .ds.access:@[.Q.l;accesstabdir;{.lg.e[`load;"Failed to load tailer accesstable with error: ",x]}];
  .ds.access:select by table from .ds.access;
  .lg.o[`load;"loaded accesstable"];
  load hsym `$.tr.basedir,"sym"
  }

/- checks to see if the IDB exists and if so loads in the accestable and IDB on tailreader startup
$[not ()~ key hsym .tr.wdbdir;reload[];.lg.o[`load;"No IDB present for this date"]];
/- logs as INF not ERR as it is expected on first time use that there is no data to load in
