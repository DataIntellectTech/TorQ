\d .tr
partitiontype:@[value;`partitiontype;`date];                               /-set type of partition (defaults to `date)
gmttime:@[value;`gmttime;1b];                                              /-define whether the process is on gmttime or not
determinepartition:{@[value;`.tr.currentpartition;                         /-function to determine the partition value
  (`date^partitiontype)$(.z.D,.z.d)gmttime]
  };
getpartition:@[value;`getpartition;determinepartition[]];
segmentid: "J"$.proc.params[`segid]
taildir:hsym `$getenv`KDBTAIL                                              /-load in taildir env variables
currentpartition:getpartition;                                             /-obtain  partition value
basedir:(raze/)1_string[.tr.taildir],"/wdb",string .tr.segmentid,"/"       /-define associated tailer base directory
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
  .tr.basedir:(raze/)1_string[.tr.taildir],"/wdb",string .tr.segmentid,"/";
  .tr.wdbdir:`$ .tr.basedir,string .tr.currentpartition;
  accesstabdir:`$ (string .tr.wdbdir),"/access";
  .lg.o[`load;"Loading intradayDB"];
  @[.Q.l ;.tr.wdbdir;{.lg.e[`load;"Failed to load intradayDB with error: ",x]}];
  .lg.o[`load;"intradayDB loaded"];
  .lg.o[`load;"loading accesstable"];
  .ds.access:@[get;hsym accesstabdir;{.lg.e[`load;"Failed to load tailer accesstable with error: ",x]}];
  .ds.access:select by table from .ds.access;
  .lg.o[`load;"loaded accesstable"];
  mostrecent:`location`table xkey update location:.proc.procname, proctype:.proc.proctype from .ds.access;
  (neg .servers.getservers[`proctype;`gateway;()!();1b;1b][`w]) @\:(`.ds.updateaccess;mostrecent);
  load hsym `$.tr.basedir,"sym"
  }

/-startup
.servers.startup[];
/- checks to see if the IDB exists and if so loads in the accestable and IDB on tailreader startup
$[not ()~ key hsym .tr.wdbdir;reload[];.lg.o[`load;"No IDB present for this date"]];
/- logs as INF not ERR as it is expected on first time use that there is no data to load in
