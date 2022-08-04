\d .tr
  2 partitiontype:@[value;`partitiontype;`date];                               /-set type of partition (defaults to `date)
  3 gmttime:@[value;`gmttime;1b];                                              /-define whether the process is on gmttime or not
  4 determinepartition:{@[value;`.tr.currentpartition;                         /-function to determine the partition value
  5   (`date^partitiontype)$(.z.D,.z.d)gmttime]
  6   };
  7 getpartition:@[value;`getpartition;determinepartition[]];
  8 segmentid: "J"$.proc.params[`segid]
  9 taildir:hsym `$getenv`KDBTAIL                                              /-load in taildir env variables
 10 currentpartition:getpartition;                                             /-obtain  partition value
 11 basedir:(raze/)1_string[.tr.taildir],"/wdb",string .tr.segmentid,"/"       /-define associated tailer base directory
 12 wdbdir:`$ basedir,string currentpartition                                  /-define IDB direction
 13
 14 \d .
 15 endofday:{[pt]
 16   /- end of day function that will be triggered by EOD Sorter once IDB is copied to HDB
 17   /-  updates partition and loads in next days partition
 18   .lg.o[`eod;"End of day message received - ",spt:string pt];
 19   .tr.currentpartition:pt+1;
 20   reload[];
 21   }
 22
 23 reload:{
 24   /- function to define the access table and IDB dir and then reload both tables
 25   /- reload is triggered by tailer after savedown occurs
 26   .tr.basedir:(raze/)1_string[.tr.taildir],"/wdb",string .tr.segmentid,"/";
 27   .tr.wdbdir:`$ .tr.basedir,string .tr.currentpartition;
 28   accesstabdir:`$ .tr.basedir,"access";
 29   .lg.o[`load;"Loading intradayDB"];
 30   @[.Q.l ;.tr.wdbdir;{.lg.e[`load;"Failed to load intradayDB with error: ",x]}];
 31   .lg.o[`load;"intradayDB loaded"];
 32   .lg.o[`load;"loading accesstable"];
 33   .ds.access:@[get;hsym accesstabdir;{.lg.e[`load;"Failed to load tailer accesstable with error: ",x]}];
 34   .ds.access:select by table from .ds.access;
 35   .lg.o[`load;"loaded accesstable"];
 36   load hsym `$.tr.basedir,"sym"
 37   }
 38
 39 /- checks to see if the IDB exists and if so loads in the accestable and IDB on tailreader startup
 40 $[not ()~ key hsym .tr.wdbdir;reload[];.lg.o[`load;"No IDB present for this date"]];
 41 /- logs as INF not ERR as it is expected on first time use that there is no data to load in
 42
